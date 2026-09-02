#include "CM3DS_rcc.h"
#include "CM3DS_gpio.h"
#include "CM3DS_MPS2.h"
#include "CM3DS_i2c.h"
#include "BL24C08.h"
#include "uart.h"
#include "CM3DS_uart.h"	
#include "CM3_retarget.h"
#include <stdio.h>
#define I2CT_FLAG_TIMEOUT         ((uint32_t)0x100)
static __IO uint32_t  I2CTimeout = I2CT_FLAG_TIMEOUT;   



/*
**EEPROM连续写入n个字节数据
**slave_addr:需要写入数据的EEPROM 的设备地址
**addr:开始写入数据的存储地址
**Buffer:要写入的数据buffer
**Num:需要写入数据的个数
*/
void I2C_ByteWrite_nBytes (uint8_t slave_addr,uint8_t addr,uint8_t* Buffer,uint8_t Num)
{	
	uint16_t addr_wtite = 0x0000;	
	EEPROM_I2C_init();
	
	// 1. 配置设备地址
	addr_wtite = 0x0000 | slave_addr;
	I2C_SlaveAddr_Config( CM3DS_MPS2_I2C, addr_wtite);
	
	// 2. 启动发送使能
	I2C_TxEnable( CM3DS_MPS2_I2C, ENABLE);
	
	// 3. 发送start信号，自动发送配置的设备地址
	I2C_GenerateSTART( CM3DS_MPS2_I2C,ENABLE);
	
	// 4. 等待从设备应答
	while(I2C_CheckACKIsFail(CM3DS_MPS2_I2C));						
	
	// 5. 写寄存器地址
	I2C_WriteByte(CM3DS_MPS2_I2C, addr);
	
	// 6. 等待从设备应答
	while(I2C_CheckACKIsFail(CM3DS_MPS2_I2C));						
	
	// 7. 写data
	while(Num)
	{
		I2C_WaitTxFIFOIsNotFull(CM3DS_MPS2_I2C);	//等待发送FIFO有空位
		I2C_WriteByte(CM3DS_MPS2_I2C, *Buffer);		//写data到发送FIFO
		while(I2C_CheckACKIsFail(CM3DS_MPS2_I2C));	//等待写data的ACK
		Buffer ++;									
		Num--;
	}
	
	// 8. 写数据完成，发送stop信号
	while((CM3DS_MPS2_I2C->STATUS1 & (1ul << 17))==0);	//确保在发送设备地址后，发送了数据
	while((CM3DS_MPS2_I2C->STATUS1 & (1ul << 4))==0);	//wait until tx fifo is empty
	I2C_GenerateSTOP( CM3DS_MPS2_I2C,ENABLE );
	
	// 9. 关闭发送使能
	I2C_WaitBusIdle(CM3DS_MPS2_I2C);
	I2C_TxEnable( CM3DS_MPS2_I2C, DISABLE);
}

/*
**从EEPROM任意地址读取数据
**slave_addr:需要读取数据的EEPROM的设备地址
**word_addr:需要开始读取数据的存储地址
**rx_data_num:读取数据的字节数
**Buffer:存储读取到数据的buffer
*/
void I2C_EEPROM_RandomRead(uint8_t slave_addr,uint8_t word_addr,uint8_t* Buffer,uint8_t rx_data_num)
{		
	uint16_t addr_read  = 0x8000;	//读写操作由SLV_ADDR的bit[15]确定，该位为0表示写操作，为1表示读操作
	uint16_t addr_wtite = 0x0000;
	EEPROM_I2C_init();
	
	// 1. 配置设备地址
	addr_wtite = 0x0000 | slave_addr;
	I2C_SlaveAddr_Config( CM3DS_MPS2_I2C, addr_wtite);
	
	// 2. 启动发送使能
	I2C_TxEnable( CM3DS_MPS2_I2C, ENABLE);
	
	// 3. 发送start信号，自动发送配置的设备地址
	I2C_GenerateSTART( CM3DS_MPS2_I2C,ENABLE);
	
	// 4. 等待从设备应答
	while(I2C_CheckACKIsFail(CM3DS_MPS2_I2C));						
	
	// 5. 写寄存器地址
	I2C_WriteByte(CM3DS_MPS2_I2C, word_addr);
	
	// 6. 等待从设备应答
	while(I2C_CheckACKIsFail(CM3DS_MPS2_I2C));	
	
	// 7. 关闭发送使能
	while((CM3DS_MPS2_I2C->STATUS1 & (1ul << 17))==0);	//确保在发送设备地址后，发送了数据
	while((CM3DS_MPS2_I2C->STATUS1 & (1ul << 4))==0);
	I2C_GenerateSTOP( CM3DS_MPS2_I2C,ENABLE );
	I2C_WaitBusIdle(CM3DS_MPS2_I2C);
	I2C_TxEnable( CM3DS_MPS2_I2C, DISABLE);
	
	// 8. 使能接收自动应答(作了软复位处理)	
	I2C_Init(CM3DS_MPS2_I2C,I2C_CLK_FREQ,I2C_Ack_Enable, I2C_Mode_Master, CM3_I2C_OWN_ADDR);
	
	// 9. 配置读设备地址
	addr_read |= slave_addr;
	I2C_SlaveAddr_Config( CM3DS_MPS2_I2C, addr_read);
	
	// 10.启动接收使能
	I2C_RxEnable( CM3DS_MPS2_I2C,ENABLE );
	
	// 11.发送start信号，自动发送读设备地址
	I2C_GenerateSTART( CM3DS_MPS2_I2C,ENABLE);

	// 12.读取接收到的数据
	while(rx_data_num)
	{
		if(rx_data_num == 1)
		{
			// 接收最后一个数据时，关闭自动应答（最后一个数据不应答）
			CM3DS_MPS2_I2C->CONTROL |= CM3DS_MPS2_I2C_NACK_ENA_Msk;
		}
		I2C_WaitReceiveReady(CM3DS_MPS2_I2C);		//等待接收FIFO非空
		*Buffer =  I2C_ReceiveByte(CM3DS_MPS2_I2C);	//读取接收到的数据
		Buffer++;
		rx_data_num--; 
	}
	
	// 13.接收完成，发送stop信号
	I2C_GenerateSTOP( CM3DS_MPS2_I2C,ENABLE );
	
	// 14.关闭接收使能
	I2C_WaitBusIdle(CM3DS_MPS2_I2C);
	I2C_RxEnable( CM3DS_MPS2_I2C,DISABLE );
}
