#include "STAR.h"
#include <stdio.h>
#include <string.h>

#define APB_NO		0										//当前APB通道序号
#define BASE_ADDR	STAR_TARGEXP0_BASE + APB_NO*0x04000000		//基地址，由通道基地址+接口序号对应的增量地址（64MB）


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
	//write
	printf("APB write:\r\n");
	for(uint32_t i = 0;i <4;i++)
	{
		write_apb_reg(BASE_ADDR+i*4,i+1);
		printf("reg_addr %x: data = %x\r\n",i*4,i+1);
	}
	//read
	printf("APB read:\r\n");
	for(uint32_t i = 0;i <4;i++)
	{
		data = read_apb_reg(BASE_ADDR+i*4);
		printf("reg_addr %x: data = %x\r\n",i*4,data);
	}
	//read reg0
	for(uint32_t i = 0;i <2;i++)
	{
		data = read_apb_reg(BASE_ADDR+0);
		printf("reg_addr0: data = %x\r\n",data);
	}
	
	
	write_apb_reg(BASE_ADDR+4,1);
	printf("Write reg_addr %x: data = %x\r\n",4,1);
	//read reg0
	for(uint32_t i = 0;i <2;i++)
	{
		data = read_apb_reg(BASE_ADDR+0);
		printf("reg_addr0: data = %x\r\n",data);
	}
}
	
	
	
	