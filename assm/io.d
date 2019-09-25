module io;

static:

/*
   IN, OUT 指令
   用于IO端口

IN: 从指定端口读取一个B,或者2B,4B
in <reg> <addr>

X86-32/64 上有效的IO地址空间从0x0000 - 0xFFFF

in al, 0x20 ;从20IO地址读取一个B到AL
in al, dx ;从dx 存储的地址读取一个B到AL

e.g. 
in al, 0x03; //从0x03端口读取1B 到al
in al, DX; //从0x03端口读取1B 到al


out <addr> <reg> 把reg中的值发送给addr地址
out dx <reg> 把reg中的值发送给addr地址

e.g.
out 0x0A, al; 把al中的值发送到0x0A地址
out dx, al; 如果地址大于0xFF,则需要发地址写入DX



 */

pragma(inline):

ubyte io_in8(const short addr)
{
    ubyte v;
    asm {
        mov DX, addr;
        in  AL, DX;
        mov v,   AL;
    }
    return v;
}

ushort io_in16(const short addr)
{
    ushort v;
    asm {
        mov DX, addr;
        in  AX, DX;
        mov v,   AX;
    }
    return v;
}

uint io_in32(const short addr)
{
    uint v;
    asm {
        mov DX, addr;
        in  AX, DX;
        mov v,  EAX;
    }
    return v;
}

//ubyte io_in64(uint addr)
//{
//}

void io_out8(const short addr, ubyte v)
{
    asm {
        mov AL, v;
        mov DX, addr;
        out DX, AL;
    }
}


void io_out16(const short addr, ushort v)
{
    asm {
        mov AX, v;
        mov DX, addr;
        out DX, AX;
    }
}

void io_out32(const short addr, uint v)
{
    asm {
        mov EAX, v;
        mov DX, addr;
        out DX, EAX;
    }
}


void io_wait()
{
        /* Port 0x80 is used for 'checkpoints' during POST. */
            /* The Linux kernel seems to think it is free for use :-/ */
        /* %%al instead of %0 makes no difference.  TODO: does the register need to be zeroed? */
}
