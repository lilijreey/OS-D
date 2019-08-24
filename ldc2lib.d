module ldc2lib;

import err;

extern(C):
//ulong __udivdi3(ulong a, ulong b)
//{
//    Err.panic("do not support div op");
//    return 0;
//}

//ulong __umoddi3(ulong a, ulong b)
//{
//    Err.panic("do not support mod op");
//    return 0;
//}

void __assert(int n)
{
    if (n==0)
    Err.panic("__assert false");
}
