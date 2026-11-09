/* Tiny_SoC 裸机固件模板(软件仿真已闭环验证, 2026-11-10)
 * 三个必踩的坑都已在此规避:
 *   1. SP 必须先初始化(否则函数调用 prologue 写未映射地址, ret 跳 0)
 *   2. _start 必须链接在 0xF0000000 复位向量(见 link.ld 的 .text.init)
 *   3. 连续 putc 必须轮询 writeAvailability, 否则 TX FIFO 溢出丢字
 * UART0 = 0x81000000; 波特率 = clk/((div+1)*(DL+1));
 * Config[2:0]=DataLength 且实际数据位=字段值+1(写 7 = 8 数据位)。 */

typedef volatile unsigned int vu32;

#define UART0 0x81000000u

static inline void wr(unsigned addr, unsigned v) { *(vu32 *)addr = v; }

static void uart_init(void)
{
    wr(UART0 + 0x8, 13);  /* 50MHz/(14*8) = 446.4kHz; 改时钟同步改分频 */
    wr(UART0 + 0xC, 7);   /* 8 data bits, no parity */
}

static void uart_putc(char c)
{
    /* 等 TX FIFO 有空位: Status@0x4 的 writeAvailability [23:16](0=满) */
    while ((((*(vu32 *)(UART0 + 0x4)) >> 16) & 0xFF) == 0)
        ;
    wr(UART0 + 0x0, (unsigned char)c);
}

static void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

__attribute__((section(".text.init"), noinline)) void _start(void)
{
    __asm__ volatile ("li sp, 0xF0000800");  /* SP 指向 OnChipRAM 内栈区 */
    uart_init();
    uart_puts("Hello TinySoC!\r\n");
    uart_puts("hqbuddy sim OK\r\n");
    for (;;)
        __asm__ volatile ("nop");
}
