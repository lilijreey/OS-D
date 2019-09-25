x86-64 smp 内核开发秘籍
===========================


## mulitboot 
主要有1,2两个版本，不兼容

检测
grub-file --is-x86-multiboot  kernel
grub-file --is-x86-multiboot2  kernel

echo $? = 0 说明ok

https://wiki.osdev.org/Multiboot


## GRUB
grub 不支持elf64 格式内核的加载
有几种方法

1.  最常见
需要先写一个加载器-32bit 然后在让加载器加载64bit 内核
即把loader 和kernel分开编译, 把kernel 作为multiboot的一个模块加载
https://wiki.osdev.org/Creating_a_64-bit_kernel_using_a_separate_loader

2. hack
把32/64bit code 链接在一起

OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386:x86-64) #有效值 objdump --info

more see: https://stackoverflow.com/questions/49473061/linking-32-and-64-bit-code-together-into-a-single-binary
https://forum.osdev.org/viewtopic.php?f=1&t=21944&hilit=OUTPUT_FORMAT

或者直接把64位代转化成elf32格式
objcopy -I elf64-x86-64 -O elf32-i386 KERNEL

对于long mode 来说

内存:
## Long mode
页表
see page_table.d

52bit 物理内存最大可寻址 4096TB
虚拟地址64位但只有低48位会经过页转换，48:63为和47bit一致
也就是说虚拟地址有效空间为 2^48 = 256T


4k 页面4级映射
虚拟地址分页
0 :11 -12 bit offset     offset   entrySize
12:20 - 9 bit 512 entry  l1       4k       
21:29 - 9 bit 512 entry  l2       2M
30:38 - 9 bit 512 entry  l3       1G
39:47 - 9 bit 512 entry  l4       512G
cr3                      total     256T



* 内核映射
  内核跟用户态各占一半的化，是虚拟地址

由于内核地址可以做到线性映射到物理地址，即把内核地址直接偏移一个固定值映射到物理地址的 M-N

由于64位下虚拟内存比物理内存大得多（可以不考虑物理内存大于虚拟内存的情况） 所以为了简单，我们可以把内核逻辑地址0 -128T，映射到
物理地址的0-128T， 另一半空间用来给用户态表示地址。 当然也可以不一半一半分配， 比如3/7分，二八分，但是意义不大。


之所以把内核用高一半的虚拟地址来表达，是因为我们想把虚拟地址0-一半留给用户态， 这样是对与用户态来说友好一些。 毕竟用户态可以使用一个较小的值表示内存。 而不是必须都得大于 0x8000000000000

对于内核虚拟地址到物理地址的映射并不是直接通过页表来走， 这样
我们对整个内核能表示的128T的虚拟地址都设置页表。 

对于128T的虚拟空间其实不需要都设置对应的页表的，因为完全不可能用这么大，所以我们只需要初始化认为能够满足需要的空间大小即可。
比如 初始化kenel-vm -  kernelVM + 64G大小的这么一段页表即可

或者根据最大物理内存进行初始化

这里还有个问题，在进入long模式之前还为打开分页时这时使用的线性地址，而且是和物理地址一一对应的。
所以还需要为当前的线性地址映射到对应的物理地址，即把0到X 大小的虚拟地址映射到0到x的物理地址


物理内存
==================================
* 得到机器物理内存

    1. 通过BISO的 中断方法可以得到
    2. 如果是grub加载则grub会收集一些信息，并在跳转到内核代码的时候
       把ebx 设置为multiboot info pointer

中断
==========================
* 实模式中断
  实模式下的中断向量表是固定死的，从内存的0到1K
  工256个，并且都是由BISO 设置,并处理的
  IDTR 自动设置为0，IRQ作为idx 查找中断向量表
  实模式先中断程序有BIOS提供

  中断触发时,CPU自动执行保护现场，并跳转到中断程序，执行完后回复现场
  1. Pushes the FLAGS register (EFLAGS[15:0]) onto the stack.
  2. Clears EFLAGS.IF to 0 and EFLAGS.TF to 0.
  3. Saves the CS register and IP register (RIP[15:0]) by pushing them onto the stack.
  4. Locates the interrupt-handler pointer (CS:IP) in the IDT by scaling the interrupt vector by four
and adding the result to the value in the IDTR.
  5. Transfers control to the interrupt handler referenced by the CS:IP in the IDT.



* 保护模式中断
 保护模式通过IDT来设置中断描述符表，表中的每个描述符叫做gate descriptors 门描述符
 包含关于中断处理程序的权限等信息和选择子, 一个gate descriptor 为8B.
 总共允许256个Gate, 1-31被系统保留，32-255给用户使用
 gate 分为3类
 1. Interrupt gates
 2. trap gates
 3. task gates

 异常分类
 有个异常可以被修复，有的不行，分为3中
 1. fault 执行中断程序后再次执行触发异常的指令
 2. trap  执行中断程序后执行触发异常指令的下一条指令
     trap 可以用来实现系统调用
 3. abort 无法继续进行



 中断触发时,根据IDT中的不同类型，执行不同的处理

 进入保护模式后，原有的IRQ中断号和CPU保留的内部异常号冲突，导致无法区分是中断发送还是内部异常，
 所以需要先重映射绑定中断，然后重新映射中断表（向量) 通过设置oGDTR 来完成

  触发流程：
  1. cpu 在IDTR.base 中查找IDT地址，根据IRQ寻址entry,
  2. 检测entry中的权限并得到selector,包含中断向量表的offset
  3. 根据selector访问GDT/LDT中的entry,得到中断程序的段基地址
  4. 根据基地址和offset 访问中断服务程序
  5. 把当前cs,eip,eflag 寄存器压栈,调用中断程序
  注意这里是IDT中存放的offset,并没有base addr, base addr 需要从GDT/LDT中活动
  对于flat 内存这里有点多此一举

   软件:
    操作系统应该保存其他寄存器,用于恢复之前的运行上下文
   
   CPU并不会告知是那个iqr被触发了，为了得到具体的irq，可以为每个向量生成代码是自动把irq压入栈中
    






* Long 模式中断处理
  机制和32位相同gate descriptor 大小变为16B
  废除了task gates



中断控制芯片
=======================================

* 8259A
旧系统使用

IDT 中断描述符表

   https://wiki.osdev.org/PIC

   * 概念 
      1. IRQ Interrupt Request
         这个是硬件概念

      2. Interrrupt Numbers 
          软件概念 一般一组IRQ 会映射为一组中断号
          因为每个对于每个硬件来说IRQ可能都是从0开始，
          但是对于系统来说需要给区分不不同硬件的不同IRQ

      3. 中断向量
         这个是相对于中断表（handler）来说的表示在表中的偏移 index
          table[idx] 这个idx叫做中断向量
      

   * real Mode 下
   Master 0~7 IRQ 对应的BISO中断号为0x08 ~ 0x0F
   Slave 0~7 IRQ 对应的BISO中断好为0x70 ~ 0x77

   * 保护模式下有个问题,因为CPU预留了0~0x1F 中断号表示内部异常
     所以无法分清到底是中断的IRQ还是CPU自身的异常,
     为了解决这种情况，一般会重映射PIC IRQ的偏移量为其他值
     一般为0x20~0x2F 16个

x86-64 调用约定
================================
前六个使用寄存器传递
%rdi, %rsi, %rdx, %rcx, %r8, %r9
返回 rax
