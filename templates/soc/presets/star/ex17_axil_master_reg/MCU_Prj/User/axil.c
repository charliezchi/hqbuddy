#include "STAR.h"
#include <stdio.h>
#include <string.h>


#define BASE_ADDR	STAR_TARGEXP0_BASE //基地址=通道基地址


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

//读取FPGA侧AXIL Slave reg
uint32_t read_axil_reg(uint32_t addr)
{
	unsigned int *data;
	data = (unsigned int *)(BASE_ADDR + addr);
	return *data;
}

//写FPGA侧AXIL Slave reg
void write_axil_reg(uint32_t addr, uint32_t data)
{
	*(uint32_t *)(BASE_ADDR + addr) = data;
}


//AXIL 读写测试
void AXIL_readWrite_test()
{
	uint32_t data;
	//write
	printf("AXIL write:\r\n");
	for(uint32_t i = 0;i <4;i++)
	{
		write_axil_reg(i*4,0xa0b0c0d0+i+1);
		printf("reg_addr %x: data = %x\r\n",i*4,0xa0b0c0d0+i+1);
	}
	
	
	
	//read
	printf("AXIL read:\r\n");
	for(uint32_t i = 0;i <4;i++)
	{
		data = read_axil_reg(i*4);
		printf("reg_addr %x: data = %x\r\n",i*4,data);
	}
}
	
	
	
	