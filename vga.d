module vga;

/*
   显卡有两种模式： 字符模式和图像模式
   开机后进入 80*25 的图像模式
   并且把显存映射到0xB800-0xBFFFF
   每个字符包含两个B，第一个是显示字符
   第二个是color[K,R,G,B,I,R,G,B]
   分为前景色和背景色,+ 闪烁

   显卡的还有300多个控制功能，比如光标的移动
   是通过IO端口控制的



*/

 enum Color:ubyte{
     Black      = 0,
     Blue       = 1,
     Green      = 2,
     Cyan       = 3,
     Red        = 4,
     Magenta    = 5,
     Brown      = 6,
     LightGray  = 7,
     DarkGray   = 8,
     LightBlue  = 9,
     LightGreen = 10,
     LightCyan  = 11,
     LightRed   = 12,
     Pink       = 13,
     Yellow     = 14,
     White      = 15,
 }



extern(C) extern __gshared size_t p4_table;
extern(C) __gshared int xx= void;
abstract final class Vga
{
public:
static:

    private __gshared Cursor cursor = void;
    struct Cursor
    {
        uint x;
        uint y;
    }


    enum {COLUMNS = 80, LINES=25}
    enum  ubyte* BASE = cast(ubyte*)0xB_8000; //VGA memory

    void init()
    {
        clearScreen();
    }
    void clearScreen()
    {
        cursor.x = 0;
        cursor.y = 0;


        foreach (i ; 0..(COLUMNS * LINES *2))
            BASE[i] = 0;

    }

    void putc(const char c, Color color=Color.White)
    {
        pragma(inline, true);

        if (c  == '\n') {
            newLine();
            return;
        }

        BASE[cursor.x*2 + cursor.y*COLUMNS*2] = c;
        BASE[cursor.x*2 + cursor.y*COLUMNS*2 + 1] =color;
        //BASE[cursor.x*2 + 0*COLUMNS*2] = c;
        //BASE[cursor.x*2 + 0*COLUMNS*2 + 1] =color;
        ++cursor.x;

    }

    void puts(const(char*) msg, Color color= Color.White)
    {
        //clearScreen();
        for (int i=0; msg[i] != '\0'; ++i)
            putc(msg[i]);
    }


    void print(A...)(A a)
    {
        char[20] numStr = void;
        
        import std.traits;
        foreach(v ; a) {
            alias UV = Unqual!(typeof(v));
            static if (is(UV == char)) putc(v);
            else static if (is(UV == char*)) puts(v);
            else static if (is(typeof(v) == string)) puts(v.ptr);
            else static if (is(UV == bool)) puts(v ? "true":"false");
            else static if (is(UV == byte)  || is(UV == ubyte) ||
                            is(UV == short) || is(UV == ushort) ||
                            is(UV == int)   || is(UV == uint) ||
                            is(UV == long)   || is(UV == ulong))
            {

                if (v == 0) {
                    putc('0');
                    continue;
                }

                ulong n = v;
                bool isNeg = false;
                if (v < 0) {
                    isNeg = true;
                    if (n != 1UL<<63)
                        n = -v;
                }

                int i=0;
                while(n !=0 ) {
                    numStr[i++] = (n%10) + '0';
                    n/=10;
                }

                if (isNeg) 
                    putc('-');

                while (--i >= 0)
                    putc(numStr[i]);
            }
            else
                static assert(false);
        }
    }


    void println(A...)(A a)
    {
        print(a);
        newLine();
    }


    void putsln(const char *msg, Color color= Color.White)
    {
        pragma(inline, true);
        puts(msg, color);
        newLine();
    }

    void newLine()
    {
        pragma(inline, true);
        ++cursor.y;
        cursor.x=0;
    }


    void showGreeting()
    {
        const char *msg= "Hello OS :) Powered by Dlang !!!";
        putsln(msg);
    }

}

