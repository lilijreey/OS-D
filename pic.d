
module pic

/*
   8259A 中断

   一般是两个8259A chips 级联, echo chip has 8 irq
   slave-pic 级联到主的IRQ2上

   https://wiki.osdev.org/PIC

   * 概念 
      1. IRQ Interrupt Request
         这个是硬件概念

      2. Interrrupt Numbers 
          软件概念 一般一组IRQ 会映射为一组中断号
          因为每个对于每个硬件来说IRQ可能都是从0开始，
          但是对于系统来说需要给区分不不同硬件的不同IRQ

      3. 中断向量
         这个是相对于中断表（handler）来说的表示在表中的偏移 index
          table[idx] 这个idx叫做中断向量
      

   * real Mode 下
   Master 0~7 IRQ 对应的BISO中断号为0x08 ~ 0x0F
   Slave 0~7 IRQ 对应的BISO中断好为0x70 ~ 0x77

   * 保护模式下有个问题,因为CPU预留了0~0x1F 中断号表示内部异常
     所以无法分清到底是中断的IRQ还是CPU自身的异常,
     为了解决这种情况，一般会重映射PIC IRQ的偏移量为其他值
     一般为0x20~0x2F 16个


    * 编程接口

      ICW0
      ICW1
      ICW2
      ICW3




*/
