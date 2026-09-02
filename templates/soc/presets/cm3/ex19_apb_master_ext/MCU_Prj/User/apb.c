#include "CM3DS_MPS2.h"
#include <stdio.h>
#include <string.h>

#define CH0_M00_BASE_ADDR	CM3DS_MPS2_TARGEXP0_BASE + 0*0x02000000		//基地址，由通道基地址+接口序号对应的增量地址（32MB）
#define CH0_M01_BASE_ADDR	CM3DS_MPS2_TARGEXP0_BASE + 1*0x02000000		//基地址，由通道基地址+接口序号对应的增量地址（32MB）


//软件延时
int delay_ms_soft(int ms)
{
	int i,j;
	for(i=0;i<ms;i++)
	{
		for(j=0;j<3000;j++);
	}
	
	return 0;
}

//读取FPGA侧APB Slave reg
uint32_t read_apb_reg(uint32_t addr)
{
	unsigned int *data;
	data = (unsigned int *)addr;
	return *data;
}

//写FPGA侧APB Slave reg
void write_apb_reg(uint32_t addr, uint32_t data)
{
	*(uint32_t *)addr = data;
}


//APB 读写测试
void APB_readWrite_test()
{
	uint32_t data;
	//M00 write
	printf("APB0 write:\r\n");
	for(uint32_t i = 0;i <4;i++)
	{
		write_apb_reg(CH0_M00_BASE_ADDR+i*4,0xaabbcc00+i+1);
		printf("reg_addr %x: data = %x\r\n",i*4,0xaabbcc00+i+1);
	}
	//M01 write
	printf("APB1 write:\r\n");
	for(uint32_t i = 0;i <4;i++)
	{
		write_apb_reg(CH0_M01_BASE_ADDR+i*4,0x11bbcc00+i+1);
		printf("reg_addr %x: data = %x\r\n",i*4,0x11bbcc00+i+1);
	}
	
	//M00 read
	printf("APB0 read:\r\n");
	for(uint32_t i = 0;i <4;i++)
	{
		data = read_apb_reg(CH0_M00_BASE_ADDR+i*4);
		printf("reg_addr %x: data = %x\r\n",i*4,data);
	}
	//M01 read
	printf("APB1 read:\r\n");
	for(uint32_t i = 0;i <4;i++)
	{
		data = read_apb_reg(CH0_M01_BASE_ADDR+i*4);
		printf("reg_addr %x: data = %x\r\n",i*4,data);
	}
}
	
	
	