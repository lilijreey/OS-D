module memory;

extern(C)
{
void* memset(void *s, int c, ulong n)
{
    //TODO 优化

    ubyte* mem =cast(ubyte*)s;
    foreach(i; 0 .. n)
        mem[i] = cast(ubyte)c;

    return s;
}

}

