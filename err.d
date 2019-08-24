module err;

import vga;


abstract final class Err 
{
public:
static:

 //@noreturn
 void panic(const char *msg)
 {
     Vga.puts("Painc:", Color.Red);
     Vga.puts(msg, Color.Red);

     asm {
         hlt;
     loop:
         jmp loop;
     }
 }

}
