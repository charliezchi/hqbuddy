#include "CM3DS_gpio.h"
#include "CM3DS_MPS2.h"
#include "CM3DS_uart.h"
#include "CM3_retarget.h"
#include "uart.h"
#include "apb.h"

#include <stdio.h> 
#include <string.h> 

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



void delay_ms(uint16_t dly)
{
	uint32_t i,j;
	for(i=0;i<dly;i++)
	{
		for(j=0;j<1000;j++);
	}
}



int main(void)
{	
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
	
	
	/*uart0初始化*/
	uart0_init(115200);
	printf("STAR APB test...\r\n");
	APB_readWrite_test();
	while(1)
	{
		delay_ms(100);
	}
}


