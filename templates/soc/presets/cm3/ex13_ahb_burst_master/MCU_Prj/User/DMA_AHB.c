#include "uart.h"
#include "CM3DS_rcc.h"
#include "CM3DS_gpio.h"
#include "CM3DS_uart.h"	
#include "CM3DS_MPS2.h"
#include "CM3DS_dma.h"	
#include "DMA_AHB.h"	
#include <stdio.h>
#include <string.h>

#define  wr_data_num 32

uint32_t wrBuffArr[128];//__attribute__((at(0x0004000)))
uint32_t rdBuffArr[128];

uint8_t TrFinishFlag =0;	//DMA传输完成标志

void DMA_Delay_ms(unsigned int ms)
{
	unsigned int i, j;
	for (i = 0; i <= ms; i++)
	{
		for(j= 0; j <= 1000; j++);
	}
}

/*DMA中断设置*/
void DMA_interrupt_init(void)
{
	/*使能DMA 终端计数中断 用于DMA的发送完成中断*/
	NVIC_ClearPendingIRQ(DMACINTTC);
	NVIC_EnableIRQ(DMACINTTC);
	
}

/*DMA计数中断服务函数*/
void DMACINTTC_Handler(void)
{
	ITStatus state;
	
	state=DMA_Get_TCInterruptStatus(CM3DS_MPS2_DMA,DMA_Channel_0);
	if(state==SET) //channel0
	{
		DMA_Interrupt_Clear(CM3DS_MPS2_DMA,DMA_Channel_0,DMA_INT_TC);
		TrFinishFlag =1;
		printf("--------------- DMA Transfer Complete-------------\n");
	}
	
	state=DMA_Get_TCInterruptStatus(CM3DS_MPS2_DMA,DMA_Channel_1);
	if(state==SET) //channel1
	{
		DMA_Interrupt_Clear(CM3DS_MPS2_DMA,DMA_Channel_1,DMA_INT_TC);
	}
	
}

/*AHB burst写数据*/
void DMA_BURST_WRITE_AHB(void)
{
	int i;
	uint32_t  w_data=0xA0B0C0D0;
	DMA_InitTypedef DMA_InitStr;
	
	memset((char*)&wrBuffArr,0x0,sizeof(wrBuffArr));
	TrFinishFlag =0;
	
	DMA_interrupt_init();
	
	/*初始化需要写的数据*/
	for(i=0;i<wr_data_num;i++)
	{
		wrBuffArr[i] = w_data+i;
		printf("write data_%d to AHB by DMA is: 0x%x\r\n",i,wrBuffArr[i]);
	}
	
	/*DMA初始化配置*/
	DMA_InitStr.DMA_Source_Addr = (uint32_t)&wrBuffArr;		
	DMA_InitStr.DMA_Destination_Addr = 0xA0000000;			//AHB总线基地址
	DMA_InitStr.DMA_SourceAddr_Inc = DMA_Addr_Inc_Enable;
	DMA_InitStr.DMA_DestinationAddr_Inc = DMA_Addr_Inc_Enable;
	DMA_InitStr.DMA_SourceDataWidth = DMA_DataWidth_Word;
	DMA_InitStr.DMA_DestinationDataWidth = DMA_DataWidth_Word;
	DMA_InitStr.DMA_SourceBurstSize = DMA_BurstSize_4;
	DMA_InitStr.DMA_DestinationBurstSize = DMA_BurstSize_4;
	DMA_InitStr.DMA_Transfertype = MtoM_DMA;						//DMA传输类型 内存到内存
	DMA_InitStr.DMA_DestinationPeripheral = DMA_Peripheral_Unused;
	DMA_InitStr.DMA_SourcePeripheral = DMA_Peripheral_Unused;
	DMA_InitStr.DMA_TCInterruptEnable = DMA_TC_INT_Enable;			//DMA传输完成中断
	
	DMA_Init(CM3DS_MPS2_DMA,DMA_Channel_0,&DMA_InitStr);
	
	DMA_TransferSize_Config(CM3DS_MPS2_DMA,DMA_Channel_0,wr_data_num);
	DMA_Interrupt_Config(CM3DS_MPS2_DMA,DMA_Channel_0,DMA_INT_TC,ENABLE);
	DMA_Channel_Enable(CM3DS_MPS2_DMA,DMA_Channel_0,ENABLE);		//使能对应通道的DMA 开始传输

	/*等待DMA传输完成*/
	while(TrFinishFlag==0);	
	
	DMA_Channel_Enable(CM3DS_MPS2_DMA,DMA_Channel_0,DISABLE);		
}

/*AHB burst读数据*/
void DMA_BURST_READ_AHB(void)
{
	int i;
	DMA_InitTypedef DMA_InitStr;
	
	TrFinishFlag=0;
	memset((char*)&rdBuffArr,0x0,sizeof(rdBuffArr));
	
	DMA_interrupt_init();
	
	/*DMA初始化配置*/
	DMA_InitStr.DMA_Source_Addr = 0xA0000000;					//AHB总线基地址
	DMA_InitStr.DMA_Destination_Addr = (uint32_t)&rdBuffArr;
	DMA_InitStr.DMA_SourceAddr_Inc = DMA_Addr_Inc_Enable;
	DMA_InitStr.DMA_DestinationAddr_Inc = DMA_Addr_Inc_Enable;
	DMA_InitStr.DMA_SourceDataWidth = DMA_DataWidth_Word;
	DMA_InitStr.DMA_DestinationDataWidth = DMA_DataWidth_Word;
	DMA_InitStr.DMA_SourceBurstSize = DMA_BurstSize_4;
	DMA_InitStr.DMA_DestinationBurstSize = DMA_BurstSize_4;
	DMA_InitStr.DMA_Transfertype = MtoM_DMA;						//DMA传输类型 内存到内存
	DMA_InitStr.DMA_DestinationPeripheral = DMA_Peripheral_Unused;
	DMA_InitStr.DMA_SourcePeripheral = DMA_Peripheral_Unused;
	DMA_InitStr.DMA_TCInterruptEnable = DMA_TC_INT_Enable;			//DMA传输完成中断
	
	DMA_Init(CM3DS_MPS2_DMA,DMA_Channel_0,&DMA_InitStr);
	
	DMA_TransferSize_Config(CM3DS_MPS2_DMA,DMA_Channel_0,wr_data_num);
	DMA_Interrupt_Config(CM3DS_MPS2_DMA,DMA_Channel_0,DMA_INT_TC,ENABLE);
	DMA_Channel_Enable(CM3DS_MPS2_DMA,DMA_Channel_0,ENABLE);			//使能对应通道的DMA 开始传输
	
	/*等待DMA传输完成*/
	while(TrFinishFlag==0);
	
	/*打印读取到的数据*/
	for(i=0;i<wr_data_num;i++)
	{
		printf("read data_%d from AHB by DMA is :0x%x\r\n",i,rdBuffArr[i]);
		
	}	
}

