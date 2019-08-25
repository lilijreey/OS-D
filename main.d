module main;

import multiboot1;
import vga;
import err;
import idt;

//64 mode
extern(C) void dmain(uint magic, const MultibootInfo *info)
{
    Vga.init();
    Vga.showGreeting();

    if (magic != MULTIBOOT_BOOTLOADER_MAGIC)
    {
        Err.panic("loader not mulitboot compliant");
    }


    if (info.flags & 0x1) {
        //说明mem_lower mem_upper 有效 
        
        //   BISO有效内存空间, Qus. 做什么用的 提供给User使用的
        //   lower 从0开始到lower,
        //   upper 从1M开始到upper 基本是
        
        Vga.println("mem_lower:0-", info.mem_lower, "kB");
        Vga.println("mem_upper:1M-", info.mem_upper>>10, "MB,", info.mem_upper,"KB");
    }


    if (info.flags & 6) { //get 所有的物理内存段
        //Vga.println("memory stages addr:", info.mmap_addr, " len",info.mmap_length);
        //mmap_length 是整个buffer的大小，而不是entry的数量
        uint addr = info.mmap_addr;
        const uint end = addr + info.mmap_length;


        //0-639K Ok
        //64K recv
        //1M - 1024M Ok
        for (int i=0; addr < end; ++i) {
            const MultibootMmapEntry *ms = cast(const MultibootMmapEntry*)addr;
            Vga.println("idx[",i,"] size:", ms.size, 
                        " addr:", cast(uint)ms.addr,
                        " len:", cast(uint)ms.len, 
                        " tyep:", ms.type);

            // .size 是包含自己本身的所以要在加上.size的大小
            addr += ms.size + ms.size.sizeof;
        }
    }



    //init GDT mmap higt viraul memory to xx
    Idt.init();

    //int b=0;
    //int a = 1/b;

}
