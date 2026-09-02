#include "CM3DS_gpio.h"
#include "CM3DS_MPS2.h"
#include "CM3DS_uart.h"
#include "CM3_retarget.h"
#include "uart.h"
#include "CM3DS_i2c.h"
#include "BL24C08.h"
#include <stdio.h> 
#include <string.h> 

uint8_t Tx_Buffer[512];
uint8_t Rx_Buffer[512];

/*EEPROM 写保护WP控制管脚*/
#define EEPROM_WP_PORT CM3DS_MPS2_GPIO0
#define EEPROM_WP_PIN	GPIO_Pin_31	
					  
/*关闭EEPROM写保护*/
#define EEPROM_WP_DISABLE 	GPIO_ResetBit(EEPROM_WP_PORT,EEPROM_WP_PIN)	
					  
/*EEPROM I2C设备地址*/
#define EEPROM_DEV_ADDR 0xa0					  

//LED2 GPIO0_0
#define LED2_PORT	CM3DS_MPS2_GPIO0
#define LED2_PIN	GPIO_Pin_0
//LED3 GPIO0_1
#define LED3_PORT	CM3DS_MPS2_GPIO0
#define LED3_PIN	GPIO_Pin_1

//LED开启
#define LED2_ON		GPIO_ResetBit(LED2_PORT,LED2_PIN)
#define LED3_ON		GPIO_ResetBit(LED3_PORT,LED3_PIN)

//LED关闭
#define LED2_OFF	GPIO_SetBit(LED2_PORT,LED2_PIN)
#define LED3_OFF	GPIO_SetBit(LED3_PORT,LED3_PIN)

//SW1
#define KEY_SW1_PORT 	CM3DS_MPS2_GPIO0
#define KEY_SW1_PIN 	GPIO_Pin_2


void delay_ms(uint16_t dly)
{
	uint32_t i,j;
	for(i=0;i<dly;i++)
	{
		for(j=0;j<1000;j++);
	}
}




void EEPROM_I2C_init(void)
{
	I2C_DeInit(CM3DS_MPS2_I2C);
	
	/*将对应的GPIO复用为I2C的管脚*/
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_15,GPIO_Mode_AF);
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_I2C0SCL, ENABLE); //GPIO[15]
	
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_16,GPIO_Mode_AF);
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_I2C0SDA, ENABLE); //GPIO[16]
	/*I2C配置: I2C主模式*/
	I2C_Init(CM3DS_MPS2_I2C,I2C_CLK_FREQ,I2C_Ack_Enable, I2C_Mode_Master, CM3_I2C_OWN_ADDR);
}

int main(void)
{		
	int j=0;
	int err_flag = 0;
	int data_num=1; //开发板使用的EEPROM PageSize为16byte
	
	GPIO_DeInit(CM3DS_MPS2_GPIO0);
	
	/*LED GPIO模式设置*/
	GPIO_Mode_Set(LED2_PORT,LED2_PIN,GPIO_Mode_Output);
	GPIO_Mode_Set(LED3_PORT,LED3_PIN,GPIO_Mode_Output);
	
	/*LED2 LED3 ON*/
	LED2_ON;
	LED3_ON;
	delay_ms(1000);
	
	/*LED2 LED3 OFF*/
	LED2_OFF;
	LED3_OFF;

	uart0_init(115200);
	
	GPIO_Mode_Set(EEPROM_WP_PORT,EEPROM_WP_PIN,GPIO_Mode_Output);
	EEPROM_WP_DISABLE;	//关闭EEPROM写保护
	EEPROM_I2C_init();
	
	
	while(data_num != 17)//开发板使用的EEPROM PageSize为16byte
	{
		err_flag = 0;
		/*向EEPROM的0地址开始写入指定字节数据*/
		printf("I2C write data to EEPROM...\r\n");
		for(j=0;j<data_num;j++)
		{	
			Tx_Buffer[j] = data_num + 0xA0 +j;
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



