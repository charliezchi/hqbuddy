#include "flash_spi.h"
#include "STAR_gpio.h"
#include "STAR_spi.h"
#include "STAR_rcc.h"
#include <stdio.h> 
#include <string.h>

#define countof(a)  (sizeof(a)/sizeof(*(a)))
#define BufferSize	(countof(TxBuffer)-1)
#define FLASH_Address  0x010000
uint8_t TxBuffer[]="STAR Flash read and write tests...\r\n";
uint8_t RxBuffer[BufferSize];


SPI_TypeDef* flashSPI= STAR_SPI0;

/*SPI管脚初始化*/
void SPI_PinInit(SPI_TypeDef* spix)
{
	if(spix ==STAR_SPI0)
	{
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_CLK_OUT, ENABLE); //GPIO[7]  CLK_OUT
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_SEL, 	  ENABLE); //GPIO[8]	CS_n
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_DATA0,   ENABLE); //GPIO[9]	MOSI
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_DATA1,   ENABLE); //GPIO[10]	MISO
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_DATA2,   ENABLE); //GPIO[17]   WPn
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI0_DATA3,   ENABLE); //GPIO[18]	HOLDn
	}
	else	//SPI1
	{
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_CLK_OUT, ENABLE); //GPIO[11]  CLK_OUT
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_SEL, 	  ENABLE); //GPIO[12]	CS_n
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_DATA0,   ENABLE); //GPIO[13]	MOSI
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_DATA1,   ENABLE); //GPIO[14]	MISO
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_DATA2,   ENABLE); //GPIO[19] 	WPn
		GPIO_AF_Config( STAR_GPIO0, GPIO_AF_SPI1_DATA3,   ENABLE); //GPIO[20]	HOLDn
	}
}

/*通过SPI写1byte数据*/
void SPI_WriteByte(SPI_TypeDef* spix,uint8_t data)
{
	SPI_SendData(spix, data);
}

/*通过SPI读取1byte数据*/
uint8_t SPI_ReadByte(SPI_TypeDef* spix)
{
	while (SPI_StatusFlag_Get(spix, SPI_STATUS_RXFIFO_NOT_EMPTY) == RESET);
	return SPI_ReceiveData(spix);
}

/*等待SPI发送完成*/
static void SPI_WaitSendFinish(SPI_TypeDef* spix)
{
	while(SPI_StatusFlag_Get(spix,SPI_STATUS_TX_BSY)); 
}

/*SPI收发回环测试*/
void SPI_LoopBack_Test(SPI_TypeDef* spix)
{		
	SPI_InitTypeDef  SPI_InitStructure; 
	uint8_t data1,data2,data3,data4;
	
	SPI_PinInit(spix);
	
	SPI_DeInit(spix);
	
	/*SPI初始化配置*/
	SPI_InitStructure.SPI_ClkPreDiv = SPI_CLK_12Prescale;				//时钟预分频
	SPI_InitStructure.SPI_SCR = 0;										//时钟速率因子
	SPI_InitStructure.SPI_Mode = SPI_Mode_Master;						//主从模式
	SPI_InitStructure.SPI_DataSize = SPI_Data_Size_8bit;				//数据位数
	SPI_InitStructure.SPI_LoopBackMode = SPI_LoopBackMode_Enable;		//自环模式
	SPI_InitStructure.SPI_ClkPolarityPhase = SPI_CLK_PL_Low_PH_1Edge;	//工作模式
	SPI_InitStructure.SPI_TxRxTransmitMode = SPI_TxRxTransmit_Simultaneous;	//收发方式
	SPI_InitStructure.SPI_DataWidth = SPI_DataWidth_Standard;			//数据宽度
	SPI_Init(spix,&SPI_InitStructure);
	
	/*通过SPI发送测试数据*/
	data1=0x89;
	data2=0x34;
	printf("SPI_LoopBack_Send:dat1=0x%x,dat2=0x%x\r\n",data1,data2);
	SPI_SendData(spix, data1);
	SPI_SendData(spix, data2);
	SPI_Cmd(spix,ENABLE);
	
	data3 = SPI_ReadByte(spix);
	data4 = SPI_ReadByte(spix);
	
	SPI_Cmd(spix,DISABLE);
	printf("SPI_LoopBack_Recv:dat1=0x%x,dat2=0x%x\r\n",data3,data4);
}

/*Flash SPI初始化设置*/
void Flash_SPI_Init(void)
{
	SPI_InitTypeDef  SPI_InitStructure;
	
	SPI_PinInit(flashSPI);
	
	SPI_DeInit(flashSPI);
	
	/*SPI初始化配置*/
	SPI_InitStructure.SPI_ClkPreDiv = SPI_CLK_12Prescale;				//时钟预分频
	SPI_InitStructure.SPI_SCR = 0;										//时钟速率因子
	SPI_InitStructure.SPI_Mode = SPI_Mode_Master;						//主从模式
	SPI_InitStructure.SPI_DataSize = SPI_Data_Size_8bit;				//数据位数
	SPI_InitStructure.SPI_LoopBackMode = SPI_LoopBackMode_Disable;		//是否自环
	SPI_InitStructure.SPI_ClkPolarityPhase = SPI_CLK_PL_Low_PH_1Edge;		//工作模式
	SPI_InitStructure.SPI_TxRxTransmitMode = SPI_TxRxTransmit_TimeSharing;	//收发方式
	SPI_InitStructure.SPI_DataWidth = SPI_DataWidth_Standard;				//数据宽度
	SPI_Init(flashSPI,&SPI_InitStructure);
}

/*读取Flash ID*/
void SPI_Read_Flash_ID(void)
{
	uint8_t MID,ID1,ID2;
	
	//Flash_SPI_Init();
	
	SPI_ReceiveDataNum_Config(flashSPI, 0x0000003);
	SPI_WriteByte(flashSPI, WB_W25Q_READ_ID);
	SPI_Cmd(flashSPI,ENABLE);

	MID = SPI_ReadByte(flashSPI);
	ID1 = SPI_ReadByte(flashSPI);
	ID2 = SPI_ReadByte(flashSPI);
	SPI_Cmd(flashSPI,DISABLE);
	
	printf("FlashID:MID:0x%x ,ID:0x%x%x\r\n",MID,ID1,ID2);
}

/*Flash 写使能*/
void Flash_WriterEnable(void)
{	
	SPI_SendData(flashSPI, WB_W25Q_WRITE_EN);// Write Enable
	SPI_Cmd( flashSPI, ENABLE);
	SPI_WaitSendFinish(flashSPI);
	SPI_Cmd(flashSPI, DISABLE);
	
}

/*等待Flash空闲*/
void Flash_WaitBusyEnd(void)
{	
	uint8_t dat;
	do
	{
		SPI_ReceiveDataNum_Config(flashSPI, 1);
		SPI_SendData(flashSPI, WB_W25Q_READ_SR1);
		SPI_Cmd( flashSPI, ENABLE);
		SPI_WaitSendFinish(flashSPI);
		
		dat = SPI_ReadByte(flashSPI);
		SPI_Cmd( flashSPI, DISABLE);
	}while((dat & 0x0001) == 0x0001); //等待FLASH的状态寄存器1的BUSY位为0
}

void Flash_SectorErase(uint32_t startAddr)
{	
	SPI_SendData(flashSPI, WB_W25Q_SECTOR_ERASE);// 4KB Sector Erase
	SPI_SendData(flashSPI, (startAddr & 0xFF0000)>>16);
	SPI_SendData(flashSPI, (startAddr & 0xFF00)>>8);
	SPI_SendData(flashSPI, (startAddr & 0xFF));
	SPI_Cmd(flashSPI, ENABLE);
	SPI_WaitSendFinish(flashSPI);
	SPI_Cmd(flashSPI, DISABLE);
}

void Flash_ChipErase(void)
{		
	SPI_WriteByte(flashSPI, WB_W25Q_ALL_ERASE);// Write Enable
	SPI_Cmd( flashSPI, ENABLE);
	SPI_WaitSendFinish(flashSPI);
	SPI_Cmd( flashSPI, DISABLE);
}


/*Flash 页写*/
void Flash_PageWrite(uint8_t* wrBuf,uint32_t addr,uint16_t num)
{	
	int i;
	
	SPI_SendData(flashSPI, WB_W25Q_PAGE_PRG);// Page Write
	SPI_SendData(flashSPI, (addr & 0xFF0000)>>16);
	SPI_SendData(flashSPI, (addr & 0xFF00)>>8);	 
	SPI_SendData(flashSPI, (addr & 0xFF));
	SPI_Cmd( flashSPI, ENABLE);	

	for(i=0;i<num;i++)
	{
		SPI_SendData(flashSPI, *wrBuf);
		while(SPI_StatusFlag_Get(flashSPI,SPI_STATUS_TXFIFO_NOT_FULL)==RESET);
		wrBuf++;
	}
	SPI_WaitSendFinish(flashSPI);
	SPI_Cmd( flashSPI, DISABLE);
}

void STAR_FLASH_SectorErase(uint32_t startAddr)
{	
	Flash_WriterEnable();
	Flash_SectorErase(startAddr);
	Flash_WaitBusyEnd();
}

void STAR_FLASH_ChipErase(void)
{		
	Flash_WriterEnable();
	Flash_ChipErase();
	Flash_WaitBusyEnd();
}


void STAR_FLASH_PageWrite(uint8_t* txBuf,uint32_t addr,uint16_t bufSize)
{	
	Flash_WriterEnable();
	Flash_PageWrite(txBuf, addr, bufSize);
	Flash_WaitBusyEnd();
}


/*Flash页读*/
void STAR_FLASH_PageRead(uint8_t* rxBuf,uint32_t addr,uint16_t num)
{
	int i=0;
	
	SPI_ReceiveDataNum_Config(flashSPI, num);
	SPI_SendData(flashSPI, WB_W25Q_READ);				//Read Data Order  0x03  ×2：0x3b  ×4：0x6b
	SPI_SendData(flashSPI, (addr & 0xFF0000)>>16);	//Read Data Addr:high
	SPI_SendData(flashSPI, (addr & 0xFF00)>>8);		//Read Data	Addr:middle
	SPI_SendData(flashSPI, (addr & 0xFF));			//Read Data Addr:low
	
	SPI_Cmd(flashSPI, ENABLE);
	SPI_WaitSendFinish(flashSPI);
	
	for(i=0;i<num;i++)
	{
		*rxBuf = SPI_ReadByte(flashSPI);
		rxBuf ++;
	}
	SPI_Cmd(flashSPI, DISABLE);
}

void SPI_Flash_Test(void)
{
	uint32_t testAddr =0x0;
	
	SPI_LoopBack_Test(STAR_SPI0);
	
	Flash_SPI_Init();
	/*读取FlashID*/
	SPI_Read_Flash_ID();

	/*Flash数据读写*/
	/*Sector擦除*/
	STAR_FLASH_SectorErase(testAddr);
	printf ("STAR_FLASH_SectorErase,addr=0x%x\r\n",testAddr);
	/*按页写入数据*/
	STAR_FLASH_PageWrite(TxBuffer, testAddr,BufferSize);
	printf ("STAR_FLASH_PageWrite,addr=0x%x,write_data:%s\r\n",testAddr,TxBuffer);
	/*按页读取数据*/
	memset(RxBuffer,0x0,sizeof(RxBuffer));
	STAR_FLASH_PageRead(RxBuffer,testAddr,BufferSize);
	printf ("STAR_FLASH_PageRead,addr=0x%x,read_data:%s\r\n",testAddr, RxBuffer);
}

