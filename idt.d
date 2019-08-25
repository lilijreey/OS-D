module idt;
import std.bitmanip;
import err;
import vga;


struct GateDesc {
align(1):
    ushort offset_0_15;
    ushort selector;
    ushort offset_16_31;
    /*
    15 14-13 12 11-8  7-3 2-0
    P  DPL   0  TYPE  ign IST
    */
    ushort info; //iST, Type, DPL, P
    uint   offset_32_63;
    uint   _res;

    enum {
      INFO_P_MASK = 0x8000,
      INFO_DPL_MASK =0x7000,
      INFO_TYPE_MASK = 0x0F00,
      INFO_IST_MASK = 0x0007,
    }

    enum { //long 模式下有效的type取值
        INFO_TYPE_INTERRUPT_GATE = 0xE,
        INFO_TYPE_TRAP_GATE = 0xF,
    }

    enum: ushort //info
    {
          //DLP=0 最高特权, IST=0
          INTERR_INFO = (1<<15) | (INFO_TYPE_INTERRUPT_GATE << 8),
          TRAP_INFO = (1<<15) | (INFO_TYPE_TRAP_GATE << 8),
    }


    private 
    void set(ulong _offset, ushort _info)
    {
        this.selector = 0x8;//GDT CS
        this.info = _info;
        this.offset_0_15 = _offset & 0xFFFF;
        this.offset_16_31 = (_offset >> 16) & 0xFFFF;
        this.offset_32_63 = (_offset >> 32);
        this._res=0;
    }

    void set_trap(void* fn)
    {
        set(cast(ulong)fn, TRAP_INFO);
    }

    void set_interrput(void* fn)
    { 
        set(cast(ulong)fn, INTERR_INFO);
    }
                           

    int p() const @property {
        return info & INFO_P_MASK;
    }

    int dpl() const @property {
        return info & INFO_DPL_MASK;
    }

    int type() const @property {
        return info & INFO_TYPE_MASK;
    }

    int ist() const @property {
        return info & INFO_IST_MASK;
    }
    
}

struct Idtr {
align(1):
    ushort limit; //idt table size
    ulong base_addr;
}



abstract final class Idt {
//@safe nothrow: @nogc: 
static:
    private __gshared Idtr idtr=void;
    private __gshared GateDesc[256] idt = void;
    private __gshared int xxend;

    void cpu_todo_handler() {
        Err.panic("CPU interrput todo handler");
    }

    void cpu0_div0() {
        Err.panic("CPU Exception: div 0");
    }

    public
    void init()
    {
        //全部设置一下
        //foreach(int i; 0 .. idt.length)
        //    idt[i].set_interrput(&cpu_todo_handler);


        //Vga.clearScreen();
        Vga.println(cast(ulong)&(idtr.limit));
        //设置cpu 保留0-31 给内部异常处理
        //idt[0].set_trap(&cpu0_div0);
        //if (idt[0].p)
        //    Vga.println("0 P");

        //用户自定义
        //TODO

        //load idt
        //idtr.limit = idt.sizeof -1;
        //idtr.base_addr = cast(ulong)idt.ptr;

        //auto idt_addr = &idt;
        //asm pure nothrow @nogc{
        //    mov RAX, idt_addr;
        //    lidt [RAX];
        //}

        //重新映射PIC IRQ 到自定义index
        //Master PIC 0x20
        //Slave PIC 0xA0
    }
}
