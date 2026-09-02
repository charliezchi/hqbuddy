#include "STAR.h"
#include <stdio.h>
#include <string.h>


#define WR_ADDR_OFFSET 	0x04 			//写操作地址寄存器偏移
#define WR_DATA_OFFSET 	0x08		 	//写操作数据寄存器偏移
#define RD_ADDR_OFFSET	0x0C			//读操作地址寄存器偏移
#define RD_DATA_OFFSET	0x10 			//读操作数据寄存器偏移
#define FPGA_AHB_SLAVE_ID_OFFSET 0xFFC //FPGA AHB SLAVE ID 偏移

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

//读取FPGA侧AHB Slave ID
static int ahbslave_id_check(void)
{
	unsigned int *data;
	data = (unsigned int *)(STAR_TARGEXP0_BASE + 0xFFC);
	if (*data != 0xB1)
	{
		printf("data: 0x%x;\r\n", *data);
		return 1;
	} 
	else
	{
		printf("data: 0x%x;\r\n", *data);
		return 0;
	}
}

//通过AHB读操作函数
uint32_t ahbslave_read(uint32_t address)
{
	uint32_t *data;
	data = (unsigned int *)address;
	return *data;
}

//通过AHB写操作函数
void ahbslave_write(uint32_t *address, uint32_t data)
{
	*address = data; 
}

void AHB_readWrite_test(void)
{
	int id_ok = 0;
	int i = 0;
	uint32_t rData = 0;
	uint32_t rwNum= 512;
	
	//读取AHB Slave ID
	printf("read ahb slave0...\r\n");
	id_ok = ahbslave_id_check();
	if (id_ok == 0)
	{
		printf("ahb slave ID ok.\r\n");
	}
	else
	{
		printf("ahb slave ID error.\r\n");		
	}
	
	//往FPGA RAM写入数据
	for (i = 0; i < rwNum; i++)
	{
		ahbslave_write((uint32_t *)(STAR_TARGEXP0_BASE + WR_ADDR_OFFSET), i);
		ahbslave_write((uint32_t *)(STAR_TARGEXP0_BASE + WR_DATA_OFFSET), i);
		printf("Write:wAddress:%d, wData: %d\r\n", i, i);
	}
	delay_ms_soft(10);
	//将写入的数据从FPGA RAM回读
	for (i = 0; i < rwNum; i++)
	{
		ahbslave_write((uint32_t *)(STAR_TARGEXP0_BASE + RD_ADDR_OFFSET), i);
		rData = ahbslave_read(STAR_TARGEXP0_BASE + RD_DATA_OFFSET);
		printf("Read:rAddress:%d, rData: %d\r\n", i, rData);
	}
	
}