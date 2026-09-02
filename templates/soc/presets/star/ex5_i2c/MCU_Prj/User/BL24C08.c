#include "STAR_rcc.h"
#include "STAR_gpio.h"
#include "STAR.h"
#include "STAR_i2c.h"
#include "BL24C08.h"
#include <stdio.h>

/*STAR I2C OWN_ADDR*/
#define I2C_OWN_ADDR 	0x000B

/*EEPROM I2C设备地址*/
#define EEPROM_DEV_ADDR 0xA0

/*I2C时钟频率(Hz)*/
#define I2C_CLK_FREQ	160000 //160K 


static uint8_t Tx_Buffer[256];				  
static uint8_t Rx_Buffer[256];

/*I2C相关GPIO管脚设置*/
void I2C_Pin_Init(void)
{
	/*将对应的GPIO复用为I2C的管脚*/
	GPIO_Mode_Set(STAR_GPIO0,GPIO_Pin_15,GPIO_Mode_AF);
	GPIO_AF_Config( STAR_GPIO0, GPIO_AF_I2C0SCL, ENABLE); //GPIO[15]
	
	GPIO_Mode_Set(STAR_GPIO0,GPIO_Pin_16,GPIO_Mode_AF);
	GPIO_AF_Config( STAR_GPIO0, GPIO_AF_I2C0SDA, ENABLE); //GPIO[16]
}

/*I2C初始化设置*/
void EEPROM_I2C_Init(void)
{
	I2C_DeInit(STAR_I2C);
	/*I2C配置: I2C主模式*/
	I2C_Init(STAR_I2C,I2C_CLK_FREQ,I2C_Ack_Enable, I2C_Mode_Master, I2C_OWN_ADDR);
}

/*
 *
 * 最多往EEPROM连续写入n个字节数据
 * slave_addr:需要写入数据的EEPROM 的设备地址
 * word_addr:开始写入数据的存储地址
 * Buffer:要写入的数据buffer
 * Num:需要写入数据的个数
 *
 */
void I2C_ByteWrite_nBytes (uint8_t slave_addr,uint16_t word_addr,uint8_t* Buffer,uint8_t Num)
{	
	uint16_t addr_wtite = 0x0000;	
	EEPROM_I2C_Init();

	// 1. 配置设备地址
	addr_wtite = 0x0000 | slave_addr;
	I2C_SlaveAddr_Config( STAR_I2C, addr_wtite);
	
	// 2. 启动发送使能
	I2C_TxEnable( STAR_I2C, ENABLE);
	
	// 3. 发送start信号，自动发送配置的设备地址
	I2C_GenerateSTART( STAR_I2C,ENABLE);
	
	// 4. 等待从设备应答
	while(I2C_CheckACKIsFail(STAR_I2C));						
	
	// 5. 写寄存器地址低8位
	I2C_WriteByte(STAR_I2C, word_addr>>8);
	while(I2C_CheckACKIsFail(STAR_I2C));
	// 6. 写寄存器地址高8位
	I2C_WriteByte(STAR_I2C, word_addr & 0xff);
	while(I2C_CheckACKIsFail(STAR_I2C));						
	
	// 7. 写data
	while(Num)
	{
		I2C_WaitTxFIFOIsNotFull(STAR_I2C);	//等待发送FIFO有空位
		I2C_WriteByte(STAR_I2C, *Buffer);		//写data到发送FIFO
		while(I2C_CheckACKIsFail(STAR_I2C));	//等待写data的ACK
		Buffer ++;									
		Num--;
	}
	
	// 8. 写数据完成，发送stop信号
	while((STAR_I2C->STATUS1 & (1ul << 17))==0);	//确保在发送设备地址后，发送了数据
	while((STAR_I2C->STATUS1 & (1ul << 4))==0);   //wait until tx fifo is empty
	I2C_GenerateSTOP( STAR_I2C,ENABLE );
	
	// 9. 关闭发送使能
	I2C_WaitBusIdle(STAR_I2C);
	I2C_TxEnable( STAR_I2C, DISABLE);
}

/*
 *
 * EEPROM任意地址读取
 * slave_addr:需要读取数据的EEPROM的设备地址
 * word_addr:需要开始读取数据的存储地址
 * Buffer:存储读取到数据的buffer
 * rx_data_num:读取数据的字节数
 *
*/
void I2C_EEPROM_RandomRead(uint8_t slave_addr,uint16_t word_addr,uint8_t* Buffer,uint16_t rx_data_num)
{		
	uint16_t addr_read  = 0x8000;	//读写操作由SLV_ADDR的bit[15]确定，该位为0表示写操作，为1表示读操作
	uint16_t addr_wtite = 0x0000;
	EEPROM_I2C_Init();
	
	// 1. 配置设备地址
	addr_wtite = 0x0000 | slave_addr;
	I2C_SlaveAddr_Config( STAR_I2C, addr_wtite);
	
	// 2. 启动发送使能
	I2C_TxEnable( STAR_I2C, ENABLE);
	
	// 3. 发送start信号，自动发送配置的设备地址
	I2C_GenerateSTART( STAR_I2C,ENABLE);
	
	// 4. 等待从设备应答
	while(I2C_CheckACKIsFail(STAR_I2C));						
	
	// 5. 写寄存器地址低8位
	I2C_WriteByte(STAR_I2C, word_addr>>8);
	while(I2C_CheckACKIsFail(STAR_I2C));
	// 6. 写寄存器地址高8位
	I2C_WriteByte(STAR_I2C, word_addr & 0xff);
	while(I2C_CheckACKIsFail(STAR_I2C));		
	
	// 7. 关闭发送使能
	while((STAR_I2C->STATUS1 & (1ul << 17))==0);	//确保在发送设备地址后，发送了数据
	while((STAR_I2C->STATUS1 & (1ul << 4))==0);   //wait until tx fifo is empty
	I2C_GenerateSTOP( STAR_I2C,ENABLE );
	I2C_WaitBusIdle(STAR_I2C);
	I2C_TxEnable( STAR_I2C, DISABLE);
	
	// 8. 使能接收自动应答(作了软复位处理)	
	I2C_Init(STAR_I2C,I2C_CLK_FREQ,I2C_Ack_Enable, I2C_Mode_Master, I2C_OWN_ADDR);
	
	// 9. 配置读设备地址
	addr_read |= slave_addr;
	I2C_SlaveAddr_Config( STAR_I2C, addr_read);
	
	// 10.启动接收使能
	I2C_RxEnable( STAR_I2C,ENABLE );
	
	// 11.发送start信号，自动发送读设备地址
	I2C_GenerateSTART( STAR_I2C,ENABLE);
	// 6. 等待从设备应答
	while(I2C_CheckACKIsFail(STAR_I2C));
	// 12.读取接收到的数据
	while(rx_data_num)
	{
		if(rx_data_num == 1)
		{
			// 接收最后一个数据时，关闭自动应答（最后一个数据不应答）
			STAR_I2C->CONTROL |= I2C_Ack_Set_Mask;
		}
		I2C_WaitReceiveReady(STAR_I2C);		//等待接收FIFO非空
		*Buffer =  I2C_ReceiveByte(STAR_I2C);	//读取接收到的数据
		Buffer++;
		rx_data_num--; 
	}
	
	// 13.接收完成，发送stop信号
	I2C_GenerateSTOP( STAR_I2C,ENABLE );
	
	// 14.关闭接收使能
	I2C_WaitBusIdle(STAR_I2C);
	I2C_RxEnable( STAR_I2C,DISABLE );
}

void EEPROM_ReadWrite_test(void)
{
	int j=0;
	int err_flag = 0;
	uint16_t data_num=1;
	uint16_t rw_addr=0;
	
	I2C_Pin_Init();
	
	while(data_num != 65)//开发板使用的EEPROM PageSize为64byte
	{
		err_flag = 0;
		/*向EEPROM的0地址开始写入指定字节数据*/
		printf("I2C write data to EEPROM...\r\n");
		for(j=0;j<data_num;j++)
		{	
			Tx_Buffer[j] = data_num + j;
			printf("0x%x ", Tx_Buffer[j]);	
		}
		printf("\r\n");
		
		I2C_ByteWrite_nBytes(EEPROM_DEV_ADDR,0x00,Tx_Buffer,data_num);
		
		
		delay_ms(100);	
		
		/*从EEPROM的0地址连续读取指定字节数据，验证之前写入的数据*/
		printf("I2C read data from EEPROM...\r\n");
		memset(Rx_Buffer,0x0,sizeof(Rx_Buffer));
		I2C_EEPROM_RandomRead(EEPROM_DEV_ADDR,0x00,Rx_Buffer,data_num);

		for(j=0;j<data_num;j++)
		{		
			printf("0x%x ", Rx_Buffer[j]);	
		}
		printf("\r\n");
	
		for(j=0;j<data_num;j++)
		{	
			if(Tx_Buffer[j] !=  Rx_Buffer[j])
			{
				err_flag = 1;
				printf("j = %d,tx = 0x%x and rx = 0x%x \r\n", j, Tx_Buffer[j],Rx_Buffer[j]);
			}
		}
		
		if(err_flag == 0)
			printf("test %d OK!\r\n",data_num);
		else
			printf("test %d ERROR!\r\n",data_num);
		
		data_num++;
	}
	
}
