module page_table;

/** AMD64

52bit 物理内存最大可寻址 4096TB
虚拟地址64位但只有低48位会经过页转换，48:63为和47bit一致
也就是说虚拟地址有效空间为 2^48 = 256T

4k 页面4级映射
虚拟地址分页
0 :11 -12 bit offset     offset   entrySize
12:20 - 9 bit 512 entry  l1       4k       
21:29 - 9 bit 512 entry  l2       2M
30:38 - 9 bit 512 entry  l3       1G
39:47 - 9 bit 512 entry  l4       512G
cr3                      total     256T

内核使用线性映射

Qus:  不可用的内存
Qus: 物理内存管理

*/

final class PageTable
{
    public:
    static:

    //完成boot.asm 中pl_
    void eraly_init()
    {
        //初始化完

    }

}
