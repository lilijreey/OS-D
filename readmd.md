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

  中断触发时,CPU自动执行保护现场，并跳转到中断程序，执行完后
  回复现场



* 保护模式中断
 保护模式通过IDT来设置中断向量表

  中断触发时,根据IDT中的不同类型，执行不同的处理


x86-64 调用约定
================================
前六个使用寄存器传递
%rdi, %rsi, %rdx, %rcx, %r8, %r9
