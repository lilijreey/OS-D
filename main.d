module main;

import multiboot1;
import vga;
import err;

extern(C)
{

 extern __gshared int _vga_x;
 extern __gshared int _vga_y;
}

//64 mode
extern(C) void dmain(uint magic, const MultibootInfo *info)
{
    //ubyte* BASE = cast(ubyte*)0xB_8000; //VGA memory
    //BASE[20] = 'a';
    //BASE[22] = 'a';
    //BASE[24] = 'a';
    //if (magic != MULTIBOOT_BOOTLOADER_MAGIC)
    //{
    //    Err.panic("loader not mulitboot compliant");
    //BASE[30] = 'a';
    //BASE[32] = 'a';
    //BASE[34] = 'a';
    //}


    Vga.clearScreen();
    //Vga.showGreeting();
    //BASE[50] = 'b';
    //BASE[52] = 'b';
    //BASE[54] = 'b';

    Vga.println(cast(ulong)&_vga_x);
    //if (&_vga_x == &_vga_x)
    //{
    //    Vga.putc('=');
    //}
    //if (p4_table == p3_table)
    //{
    //    Vga.putc('=');

    //}
    //uint x = (ulong)(&_vga_x)>>32;
    //uint y = (ulong)(&_vga_y)>>32;
    //Vga.print(x);
    //Vga.print(y);

    //Vga.putc('X');
    //Vga.putc('X');
    //Vga.putc('X');
    //Vga.putc('X');

    //if (info.flags & 0x1) {
        //说明mem_lower mem_upper 有效 ///Vga.println(33);
        /*
           BISO有效内存空间, Qus. 做什么用的?
           lower 从0开始到lower,
           upper 从1M开始到upper 基本是
        */
        //Vga.println("mem_lower:0-", info.mem_lower, "kB");
        //Vga.println("mem_upper:1M-", info.mem_upper>>10, "MB,", info.mem_upper,"KB");
    //}


    //if (info.flags & 6) { //get 所有的物理内存段
    //    //Vga.println("memory stages addr:", info.mmap_addr, " len",info.mmap_length);
    //    //mmap_length 是整个buffer的大小，而不是entry的数量
    //    uint addr = info.mmap_addr;
    //    const uint end = addr + info.mmap_length;


    //    //0-639K Ok
    //    //64K recv
    //    //1M - 1024M Ok
    //    for (int i=0; addr < end; ++i) {
    //        const MultibootMmapEntry *ms = cast(const MultibootMmapEntry*)addr;
    //        Vga.println("idx[",i,"] size:", ms.size, 
    //                    " addr:", cast(uint)ms.addr,
    //                    " len:", cast(uint)ms.len, 
    //                    " tyep:", ms.type);

    //        // .size 是包含自己本身的所以要在加上.size的大小
    //        addr += ms.size + ms.size.sizeof;
    //    }
           
    //}


}
