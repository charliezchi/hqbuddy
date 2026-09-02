#include "STAR_rcc.h"
#include "STAR_gpio.h"
#include "STAR.h"	
#include "STAR_dma.h"	
#include "dma.h"	
#include "STAR_spi.h"
#include <stdio.h>	

uint8_t testDataBuf[32];
uint8_t testDataBuf2[32];

SPI_TypeDef* SPIx = STAR_SPI0;

static void Delay_ms(unsigned int ms)
{
	unsigned int m, n;
	for (m = 0; m <= ms; m++)
	{
		for(n= 0; n <= 3000; n++);
	}
}

/*等待SPI发送完成*/
static void SPI_WaitSendFinish(SPI_TypeDef* spix)
{
	while(SPI_StatusFlag_Get(spix,SPI_STATUS_TX_BSY)); 
}

void DMA_interrupt_init(void)
{
	/*使能DMA 终端计数中断 用于DMA的发送完成中断*/
	NVIC_ClearPendingIRQ(DMACINTTC_IRQn);
	NVIC_EnableIRQ(DMACINTTC_IRQn);
	
	/*使能DMA中断(包含DMA计数中断和DMA错误中断)*/
	//NVIC_ClearPendingIRQ(DMACINTR_IRQn);
	//NVIC_EnableIRQ(DMACINTR_IRQn);
}

/*SPI管脚初始化*/
void SPI_PinInit(SPI_TypeDef* spix)
{
	if(spix ==STAR_SPI0)
	{
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_CLK_OUT, ENABLE); //GPIO[7]  CLK_OUT   P9
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_SEL, 	  ENABLE); //GPIO[8]	CS_n      P10
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_DATA0,   ENABLE); //GPIO[9]	MOSI	    R11
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_DATA1,   ENABLE); //GPIO[10]	MISO      M12
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_DATA2,   ENABLE); //GPIO[17] WPn       K11
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_DATA3,   ENABLE); //GPIO[18]	HOLDn     R12
	}
	else	//SPI1
	{
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_CLK_OUT, ENABLE); //GPIO[11]  CLK_OUT   P9
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_SEL, 	  ENABLE); //GPIO[12]	CS_n      P10
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_DATA0,   ENABLE); //GPIO[13]	MOSI	    R11
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_DATA1,   ENABLE); //GPIO[14]	MISO      M12
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_DATA2,   ENABLE); //GPIO[19] WPn       K11
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_DATA3,   ENABLE); //GPIO[20]	HOLDn     R12
	}
}

/*DMA内存空间到内存空间测试*/
void DMA_Test_MtoM(void)
{
	int i; 
	uint8_t w_data=0x22; 
	uint8_t sendNum =10;
	DMA_InitTypedef DMA_InitStr;
	
	memset((char*)&testDataBuf,0x0,sizeof(testDataBuf));		//Source Buffer
	memset((char*)&testDataBuf2,0x0,sizeof(testDataBuf2));		//Destination  Buffer
	
	printf("---------------DMA Memory-To-Memory Test---------------\r\n");
	printf("Source_Data:");
	for(i=0;i<sendNum;i++)   
	{
		testDataBuf[i]= w_data+i;
		printf("0x%x ",testDataBuf[i]);
	}
	printf("\r\n");
	printf("Start DMA transfer...\r\n");
	
	DMA_InitStr.DMA_Source_Addr = (uint32_t)&testDataBuf;
	DMA_InitStr.DMA_Destination_Addr = (uint32_t)&testDataBuf2;
	DMA_InitStr.DMA_SourceAddr_Inc = DMA_Addr_Inc_Enable;
	DMA_InitStr.DMA_DestinationAddr_Inc = DMA_Addr_Inc_Enable;
	DMA_InitStr.DMA_SourceDataWidth = DMA_DataWidth_Byte;
	DMA_InitStr.DMA_DestinationDataWidth = DMA_DataWidth_Byte;
	DMA_InitStr.DMA_SourceBurstSize = DMA_BurstSize_1;
	DMA_InitStr.DMA_DestinationBurstSize = DMA_BurstSize_1;
	DMA_InitStr.DMA_Transfertype = MtoM_DMA;						//DMA传输类型 内存到内存
	DMA_InitStr.DMA_DestinationPeripheral = DMA_Peripheral_Unused;
	DMA_InitStr.DMA_SourcePeripheral = DMA_Peripheral_Unused;
	DMA_InitStr.DMA_TCInterruptEnable = DMA_TC_INT_Enable;			//使能DMA传输完成中断
	

	DMA_Init(STAR_DMA,DMA_Channel_0,&DMA_InitStr);
	
	DMA_TransferSize_Config(STAR_DMA,DMA_Channel_0,sendNum);
	
	DMA_Interrupt_Config(STAR_DMA,DMA_Channel_0,DMA_INT_TC,ENABLE);
	
	DMA_Channel_Enable(STAR_DMA,DMA_Channel_0,ENABLE);
	
	printf("Destination_Data: ");
	
	/*读取收到的数据*/
	for(i=0;i<sendNum;i++)
	{
		printf ("0x%x ", testDataBuf2[i]);
		
	}
	printf("\r\n");
	
	DMA_Channel_Enable(STAR_DMA,DMA_Channel_0,DISABLE);
}

/*SPI初始化并发送测试数据*/
static void SPI_Init_And_Send(void)
{		
	uint8_t i;
	uint8_t dat=0xa1;
	uint8_t sendNum = 23;
	
	SPI_InitTypeDef  SPI_InitStructure; 
	uint8_t data1,data2,data3,data4;
	
	SPI_PinInit(SPIx);
	
	SPI_DeInit(SPIx);
	
	/*SPI初始化配置*/
	SPI_InitStructure.SPI_ClkPreDiv = SPI_CLK_12Prescale;				//时钟预分频
	SPI_InitStructure.SPI_SCR = 0;										//时钟速率因子
	SPI_InitStructure.SPI_Mode = SPI_Mode_Master;						//主从模式
	SPI_InitStructure.SPI_DataSize = SPI_Data_Size_8bit;				//数据位数
	SPI_InitStructure.SPI_LoopBackMode = SPI_LoopBackMode_Enable;		//自环模式
	SPI_InitStructure.SPI_ClkPolarityPhase = SPI_CLK_PL_Low_PH_1Edge;	//工作模式
	SPI_InitStructure.SPI_TxRxTransmitMode = SPI_TxRxTransmit_Simultaneous;	//收发方式
	SPI_InitStructure.SPI_DataWidth = SPI_DataWidth_Standard;			//数据宽度
	SPI_Init(SPIx,&SPI_InitStructure);
	
	/*使能SPI 接收DMA*/
	SPI_DMA_Cmd(SPIx,SPI_DMA_RX_ENABLE,ENABLE);
	
	/*SPI发送数据*/
	printf("SPI send data:");
	
	SPI_SendData(SPIx, dat);	//先往SPI发送FIFO写第一个数据 然后再开启SPI进行发送
	SPI_Cmd(SPIx, ENABLE);
	printf("0x%x ",dat);
	
	for(i=1;i<sendNum;i++)
	{
		SPI_SendData(SPIx, dat+i);
		printf("0x%x ",dat+i);
	}
	printf("\r\n");
	SPI_WaitSendFinish(SPIx);
	
	//SPI_DMA_Cmd(SPIx,SPI_DMA_RX_ENABLE,Disable);
}


/*
DMA外设到内存空间测试
SPI0 接收端通过DMA接收数据并保存到内存
SPI0 工作在自环模式下，发送的数据在接收端可以收到
*/
void DMA_SPI_Test_PtoM(void)
{
	int i; 
	uint8_t sendNum =23; 
	DMA_InitTypedef DMA_InitStr;
	
	memset((char*)&testDataBuf,0x0,sizeof(testDataBuf));

	printf("---------------DMA Peripheral-To-Memory Test---------------\r\n");
	
	DMA_InitStr.DMA_Source_Addr = 0x4000B008; 	//SPI0 Data Reg Addr
	DMA_InitStr.DMA_Destination_Addr = (uint32_t)&testDataBuf;
	DMA_InitStr.DMA_SourceAddr_Inc = DMA_Addr_Inc_Disable;
	DMA_InitStr.DMA_DestinationAddr_Inc = DMA_Addr_Inc_Enable;
	DMA_InitStr.DMA_SourceDataWidth = DMA_DataWidth_Byte;
	DMA_InitStr.DMA_DestinationDataWidth = DMA_DataWidth_Byte;
	DMA_InitStr.DMA_SourceBurstSize = DMA_BurstSize_1;
	DMA_InitStr.DMA_DestinationBurstSize = DMA_BurstSize_1;
	DMA_InitStr.DMA_Transfertype = PtoM_DMA;					//DMA传输类型 外设到内存
	DMA_InitStr.DMA_DestinationPeripheral = DMA_Peripheral_Unused; 
	DMA_InitStr.DMA_SourcePeripheral = DMA_Peripheral_SPI0RX;
	DMA_InitStr.DMA_TCInterruptEnable = DMA_TC_INT_Enable;		//使能DMA传输完成中断
	
	DMA_Init(STAR_DMA,DMA_Channel_0,&DMA_InitStr);
	DMA_TransferSize_Config(STAR_DMA,DMA_Channel_0,sendNum);
	DMA_Interrupt_Config(STAR_DMA,DMA_Channel_0,DMA_INT_TC,ENABLE);
	DMA_Channel_Enable(STAR_DMA,DMA_Channel_0,ENABLE);
	
	printf("Start DMA transfer...\r\n");
	
	/*SPI初始化并发送数据*/
	SPI_Init_And_Send();
	
	printf("Destination_Data: ");
	/*读取SPI发送的数据*/
	for(i=0;i<sendNum;i++)
	{
		printf ("0x%x ", testDataBuf[i]);
	}
	printf("\r\n");
	
	DMA_Channel_Enable(STAR_DMA,DMA_Channel_0,DISABLE);
}



/*DMA内存空间到外设设置*/
static void DMA_MemoryToPeripheral(uint8_t num)
{
	int i; 
	uint8_t  w_data = 0xB1;
	
	DMA_InitTypedef DMA_InitStr;
	
	memset((char*)&testDataBuf,0x0,sizeof(testDataBuf));		//Source Buffer
	
	printf("Source_Data: ");
	for(i=0;i<num;i++)
	{
		testDataBuf[i] = w_data+i;
		printf("0x%x ",testDataBuf[i]);
	}	
	printf("\r\n");
	
	DMA_InitStr.DMA_Source_Addr = (uint32_t)&testDataBuf;
	DMA_InitStr.DMA_Destination_Addr = 0x4000B008;					//SPI0 Data Reg Addr
	DMA_InitStr.DMA_SourceAddr_Inc = DMA_Addr_Inc_Enable;
	DMA_InitStr.DMA_DestinationAddr_Inc = DMA_Addr_Inc_Disable;
	DMA_InitStr.DMA_SourceDataWidth = DMA_DataWidth_Byte;
	DMA_InitStr.DMA_DestinationDataWidth = DMA_DataWidth_Byte;
	DMA_InitStr.DMA_SourceBurstSize = DMA_BurstSize_1;
	DMA_InitStr.DMA_DestinationBurstSize = DMA_BurstSize_1;
	DMA_InitStr.DMA_Transfertype = MtoP_DMA;						//DMA传输类型 内存到外设
	DMA_InitStr.DMA_DestinationPeripheral = DMA_Peripheral_SPI0TX;
	DMA_InitStr.DMA_SourcePeripheral = DMA_Peripheral_Unused;
	DMA_InitStr.DMA_TCInterruptEnable = DMA_TC_INT_Enable;			//使能DMA传输完成中断
	
	DMA_Init(STAR_DMA,DMA_Channel_0,&DMA_InitStr);
	
	DMA_TransferSize_Config(STAR_DMA,DMA_Channel_0,num);
	
	DMA_Interrupt_Config(STAR_DMA,DMA_Channel_0,DMA_INT_TC,ENABLE);
	
	DMA_Channel_Enable(STAR_DMA,DMA_Channel_0,ENABLE);

}

/*
DMA 内存空间到外设测试
SPI 发送端通过DMA发送数据,发送的数据在内存区域
SPI工作在自环模式下，发送的数据在接收端可以收到
*/
void DMA_SPI_Test_MtoP(void)
{
	uint8_t rx_data_spi[10];
	int i,sendNum=8,recvNum=0;
	SPI_InitTypeDef  SPI_Initstructure; 
	
	printf("---------------DMA Memory-To-Peripheral Test---------------\r\n");
	
	printf("Start DMA transfer...\r\n");
	
	/*SPI Pin设置*/
	SPI_PinInit(SPIx);	
	
	SPI_DeInit(SPIx);
	
	SPI_Initstructure.SPI_ClkPreDiv = SPI_CLK_2Prescale;
	SPI_Initstructure.SPI_SCR	= 0;						//时钟速率因子
	SPI_Initstructure.SPI_DataSize = SPI_Data_Size_8bit;
	SPI_Initstructure.SPI_ClkPolarityPhase = SPI_CLK_PL_Low_PH_1Edge;
	SPI_Initstructure.SPI_Mode = SPI_Mode_Master;
	SPI_Initstructure.SPI_LoopBackMode = SPI_LoopBackMode_Enable;     		//收发环回模式
	SPI_Initstructure.SPI_DataWidth = SPI_DataWidth_Standard;   																														 
	SPI_Initstructure.SPI_TxRxTransmitMode = SPI_TxRxTransmit_Simultaneous;	//收发同步
	
	SPI_Init(SPIx,&SPI_Initstructure);
	
	/*使能SPI发送DMA*/
	SPI_DMA_Cmd(SPIx,SPI_DMA_TX_ENABLE,ENABLE);
	SPI_Cmd( SPIx, ENABLE);
	
	/*DMA设置*/
	DMA_MemoryToPeripheral(sendNum);
	
	printf("SPI Recv Data:");
	for(i=0;i<sendNum;i++)
	{
		rx_data_spi[i] = SPI_ReceiveData(SPIx);
		printf ("0x%x ", rx_data_spi[i]);
	}
	printf("\r\n");
	
	DMA_Channel_Enable(STAR_DMA,DMA_Channel_0,DISABLE);
	
}


void DMA_test(void)
{
	DMA_interrupt_init(); //DMA中断配置
	DMA_Test_MtoM();
	DMA_SPI_Test_PtoM();
	DMA_SPI_Test_MtoP();
}

/*DMA计数中断服务函数*/
void DMACINTTC_Handler(void)
{
	ITStatus state;
	
	state=DMA_Get_TCInterruptStatus(STAR_DMA,DMA_Channel_0);
	if(state==SET) //channel0
	{
		DMA_Interrupt_Clear(STAR_DMA,DMA_Channel_0,DMA_INT_TC);
	}
	
	state=DMA_Get_TCInterruptStatus(STAR_DMA,DMA_Channel_1);
	if(state==SET)  //channel1
	{
		DMA_Interrupt_Clear(STAR_DMA,DMA_Channel_1,DMA_INT_TC);
	}
	
	printf("DMA transfer complete!\r\n");
}

/*DMA中断(包含DMA错误中断和DMA计数中断)服务函数*/
void DMACINTR_Handler(void)
{
	ITStatus state;
	
	printf("DMACINTR\n");
	state=DMA_Get_InterruptStatus(STAR_DMA,DMA_Channel_0);
	if(state==SET) //channel0
	{
		printf("channel-0 DMACINTR.\n");
		/*是否是DMA计数中断---DMA发送完成中断*/
		if(DMA_Get_TCInterruptStatus(STAR_DMA,DMA_Channel_0)==SET) //channel0
		{
			printf("channel-0 DMACINTTC,DMA transfer complete!\n");
			DMA_Interrupt_Clear(STAR_DMA,DMA_Channel_0,DMA_INT_TC);
		}
		/*是否是DMA错误中断*/
		if(DMA_Get_ErrInterruptStatus(STAR_DMA,DMA_Channel_0)==SET)
		{
			printf("channel-0 DMACINTERR,DMA error interrupt!\n");
			DMA_Interrupt_Clear(STAR_DMA,DMA_Channel_0,DMA_INT_INTERR);
		}
	}
	
	//channel1
	state=DMA_Get_InterruptStatus(STAR_DMA,DMA_Channel_1);
	if(state==SET) 
	{
		printf("channel-1 DMACINTR.\n");
		/*是否是DMA计数中断---DMA发送完成中断*/
		if(DMA_Get_TCInterruptStatus(STAR_DMA,DMA_Channel_1)==SET) 
		{
			printf("channel-1 DMACINTTC,DMA transfer complete!\n");
			DMA_Interrupt_Clear(STAR_DMA,DMA_Channel_1,DMA_INT_TC);
		}
		/*是否是DMA错误中断*/
		if(DMA_Get_ErrInterruptStatus(STAR_DMA,DMA_Channel_1)==SET)
		{
			printf("channel-1 DMACINTERR,DMA error interrupt!\n");
			DMA_Interrupt_Clear(STAR_DMA,DMA_Channel_1,DMA_INT_INTERR);
		}
	}
	
}