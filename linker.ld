OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386:x86-64) /*必须要定义这个，否则不识别64bit 指令*/
/*OUTPUT_FORMAT(elf64-x86-64)*/
ENTRY (start)

SECTIONS{
	. = 1M;

	.boot : {
		*(.boot)
	}
	.text :{
		*(.text)
		*(.text.*)
        }

	. = ALIGN (0x1000);

	.rodata  : {
	       	*(.rodata)
	       	*(.rodata.*)

        }

	. = ALIGN (0x1000);
	.data : {
		*(.data)
		*(.data.*)
	}

	. = ALIGN(0x1000);
	.bss : {
		bss = .; _bss = .; __bss = .;
		*(.bss)
		*(.bss.*)
		/**(.tbss.*)*/
		ebss = .;

	}
	end = .; _end = .; __end = .;

	 . = ALIGN(0x1000);
	   .eh_frame (NOLOAD) : { *(.eh_frame)  } : NONE
	
	/*由于只设置了2M的内存，加个断言 */
	ASSERT(end < 2M, "end > 2M")

}
