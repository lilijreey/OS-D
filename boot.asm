; 使用grub 加载内核镜像，跳转到这里
; 这时候已经是保护模式了
; doc
; https://os.phil-opp.com/multiboot-kernel/
;

;grub2 可以加载有效的multiboot标准内核

;声明multiboo2 header
; qeum -kernel 参数不支持mulitboot2 标准，只支持1标准
; 或者制作成iso文件
;The layout of the Multiboot2 header must be as follows:
;	Offset	Type	Field Name	Note
;	0	u32	magic	required
;	4	u32	architecture	required
;	8	u32	header_length	required
;	12	u32	checksum	required
;	16-XX		tags	required
;
; https://www.gnu.org/software/grub/manual/multiboot/multiboot.html
; https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#Header-magic-fieldsk
;
;
; 可以使用 grub-file --is-x86-multiboot2  <file>
; 来检测是否是有效的头， 返回值为0 表示有效
  

%define MB_MAGIC 0xE85250D6 ; v2.magic
%define MB_ARCH 0 ;x86-32 protect mode
%define MB_HEAD_LEN (mb_end - mb_header)

[section .boot]
mb_header:
	dd MB_MAGIC
	dd MB_ARCH
	dd MB_HEAD_LEN
	dd -(MB_MAGIC + MB_ARCH + MB_HEAD_LEN)

align 8, db 0
      ; tags

      ; 必须以null tag结束
      dw 0,0
      dd 8
mb_end:



; grub 跳转到这里时已经是32为保护模式了
; 并且所有寄存器的值也有规定
;所以是使用bit32
[bits 32]
[section .text]
[global start]
[extern start32] 


start:
	;设置esp, 支持push指令调用 因为push 指令会sub %4 esp
	mov esp, early_stack_top

	; 检测不通过 Why?
	;call check_is_load_by_multiboot

	;call biosVgaClearScreen
	;call biosVgaShowGreeting

	;call cpuidCheckSupport
	;call cpuidCheckHasLongMode
     

	mov eax, 0x2f592f41
	mov [0xb8000], eax
	; 尽快进入long mode 因为在32bit模式下必须调用32位代码
	; set IDT

init_page_table: 
;这里设置映射0-2M的VM地址到物理地址0-2M的页表，之后的到进入64bit后在D中初始化
;0-2M 需要初始化的页表有
;        one l4[0] 512G
;        one l3[0] 1G
;        one l2[0] 2M 为了方便这里直接设置2M页表，从而避免初始化512个1l表
;       512  l1[0-511] 

;0 :11 -12 bit offset     offset   entrySize
;12:20 - 9 bit 512 entry  l1       4k       
;21:29 - 9 bit 512 entry  l2       2M
;30:38 - 9 bit 512 entry  l3       1G
;39:47 - 9 bit 512 entry  l4       512G
;cr3                      total    256T

	%define PD_PRESENT (1<<0)
	%define PD_RW (1<<1)
	%define PD_2MB (1<<7)
	;set p4_table[0] = p3_table
	mov eax, p3_table
	or eax, PD_PRESENT | PD_RW
	mov [p4_table], eax

	;set p3_table[0] = p2_table
	mov eax, p2_table
	or eax, PD_PRESENT | PD_RW
	mov [p3_table], eax

	;set p2_table[0] 0
	mov eax, PD_PRESENT |PD_RW | PD_2MB
	mov [p2_table],eax


	mov [p2_table],eax

	;cr3=p4_table
	mov eax, p4_table
	mov cr3, eax

	;enable cr4.PAE
	mov eax, cr4
	or eax, 1 << 5 ;PAE
	mov cr4, eax

	;set long mode
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	;enable page
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	;; set GDT to 64bit
        lgdt [gdt64_pointer]

	;;load new 64bit cs with jmp
	jmp 8:start64


cpuhalt:
	hlt
	jmp cpuhalt

; 检测是否被multiboot 兼容loader加载
;check_is_load_by_multiboot:
;    ; 检测 eax 是否被设置为0x36d76289
;    cmp eax, 0x36d76289
;    jne .failed

;    push check_multiboot_ok_msg
;    call biosVgaShowMsg
;    add esp, 4

;    ret

;.failed:
;    push check_multiboot_error_msg
;    call biosVgaShowMsg
;    add esp, 4
    ;hlt

[bits 64]

[extern biosVgaClearScreen]
[extern biosVgaShowGreeting]
[extern biosVgaShowMsg]

[extern cpuidCheckSupport]
[extern cpuidCheckHasLongMode]
start64:
	;set clear all segment reg to 0
	mov ax, 0
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov rsp, early_stack_top

	mov rax, 0x2f592f412f4b2f4f
	mov qword [0xb8010], rax

	call biosVgaClearScreen
	;call biosVgaShowGreeting

    hlt

;fn show_msg(const char *msg:ax) -> void

;fn clear_screen:
;clear_scree:
;clear_screen:
	;32 为保护模式下无法调用BISO内置中断程序





     

;x86-32 调用ABI
;D 语言和C语言的调用约定相同
;第1到6参数

[section .rodata]

;check_multiboot_error_msg:
;db "ERR: kernel not load by multiboot2 loader",0

;check_multiboot_ok_msg:
;db "Check multiboot ok.",0

%define GDT_PRESENT (1<<47)
%define GDT_EXEC    (1<<43)
%define GDT_64_CODE (1<<53)
%define GDT_TYPE    (1<<44)
gdt64:
     dq 0; //null entry 规定第一项必须为空
gdt64_code:
     ;code segment 虽然long 模式没有段管理了，但是对应的段权限还是使用gdt entry来控制
     dq GDT_PRESENT | GDT_EXEC | GDT_64_CODE | GDT_TYPE
gdt64_pointer:
     dw $ - gdt64 -1 ;len
     dq gdt64 ;addr 
   


[section .bss]

[global p4_table]
[global p3_table]
[global p2_table]
align 4096, db 0
p4_table:
	resb 4096
p3_table:
	resb 4096
p2_table:
    	resb 4096

align 64, db 0
;定义一个Stack空间; 16 KiB if you're wondering
early_stack_base:
	;resb      1<<16 
	resb      4096
early_stack_top:
