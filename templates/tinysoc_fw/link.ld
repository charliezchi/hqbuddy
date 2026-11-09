ENTRY(_start)
SECTIONS
{
    . = 0xF0000000;   /* OnChipRAM 基址 = 复位向量, _start 必须置顶 */
    .text   : { KEEP(*(.text.init)) *(.text*) *(.rodata*) }
    .data   : { *(.data*) }
    .bss    : { *(.bss*) *(COMMON) }
}
