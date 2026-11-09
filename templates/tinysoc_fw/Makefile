# Tiny_SoC 裸机固件构建(hqbuddy -tinysoc fw 消费产物 fw.bin)
# RISCV_PATH 指向 xPack riscv-none-embed-gcc 工具链根目录(含 bin/)
RISCV_PATH ?= $(error set RISCV_PATH=<xpack-riscv-none-embed-gcc root>)
TOOLBIN := $(RISCV_PATH)/bin
PREFIX  := riscv-none-embed-

CFLAGS  := -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -O2 -Wall
LD      := $(TOOLBIN)/$(PREFIX)gcc $(CFLAGS) -Tlink.ld

fw.bin: main.c link.ld
	$(LD) -o fw.elf main.c
	$(TOOLBIN)/$(PREFIX)objcopy -O binary fw.elf fw.bin
	@echo "[OK] fw.bin ready -> hqbuddy -tinysoc fw fw.bin"

clean:
	rm -f fw.elf fw.bin
