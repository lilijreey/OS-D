// COMMENT @ include by nasm
module cpuid;

import err;
import vga;

abstract final class CPUID
{
    /*
    CPUID 通过EAX传递参数然后调用cpuid
    CPUID 提供的函数分为`标准函数` 和`扩展函数`
    `标准函数` EAX值为 0000_0000h-0000_FFFFh
    `扩展函数` EAX值为 8000_0000h-8000-FFFFh
     
     @return 返回值通过eax,ebx,ecx,edx 返回
    */
public:
static:
    void checkSupport() 
    {
        //如果FLAGS ID-bit 可以翻转来,则支持cpuid 指令
        //https://wiki.osdev.org/Setting_Up_Long_Mode#Detection_of_CPUID
        bool has = false;
        asm {
            /*
            eax = flags
            ecx = eax
            eax |= 1<<21
            flags = eax;  看是否能设置上
            eax = flags
            if (eax == ecx) not has cpuid
            */

            //eax = FLAGS
            pushfd ; 
            pop EAX;

            mov ECX, EAX;

            // Flip the ID-bit 21
            xor EAX, 1 << 21;
            
            //FLAGS = eax
            push EAX;
            popfd;

            //set FLAGS is can set ID-bit
            pushfd;
            pop EAX;

            //restore flags
            push ECX;
            popfd;

            //compare EAX == ECX
            xor EAX, ECX;
            jz noCPUID;
            mov EAX, 1;
            jmp endif;
        noCPUID:
            mov EAX, 0;
        endif:
            mov has, EAX;
        }

        if (has) {
            BiosVga.showMsgln("Check CPUID support.");
            return;
        }
         
         Err.panic("Check CPUID not support.");
    }

    void checkHasLongMode()
    {
        showVendorId();
        //需要先确认是否支持扩展指令 如果支持再检测是否支持long mode
        bool has=false;
        
        asm {
            push EAX;
            mov EAX, 0x8000_0000;
            cpuid;
            cmp EAX, 0x8000_0001; //如果大于= 说明支持扩展模式
            jb no_long_mode;

            mov EAX, 0x8000_0001;//如果EDX 29bit 为1 说明支持Long mode
            cpuid; 
            test EDX, 1 << 29;
            jz no_long_mode;
            mov EAX, 1;
            jmp endif;

        no_long_mode:
            mov EAX,0;

        endif:
            mov has, EAX;
            pop EAX;
        }

        if (has) {
            BiosVga.showMsgln("Cpu support long mode");
            return;
        }
            Err.panic("Cpu not support long mode.");

    }

    void showVendorId()
    {
        //EAX=0 return 12-chars string, in EBX,EDX,ECX
        //char[13] vendor = void; //do not init
        char[13] vendor = "no vendor"; //do not init
        asm {
            push EAX;
            push EBX;
            push EDX;
            push ECX;

            mov EAX, 0;
            cpuid;
            mov [vendor], EBX;
            mov [vendor+4],EDX;
            mov [vendor+8],ECX;

            pop ECX;
            pop EDX;
            pop EBX;
            pop EAX;
        }
        vendor[vendor.sizeof-1] = '\0';

        BiosVga.showMsgln(vendor.ptr);

    }


}

extern(C)
{

	void cpuidCheckSupport()
    {
        CPUID.checkSupport();
    }

	void cpuidCheckHasLongMode()
    {
        CPUID.checkHasLongMode();
    }

}

