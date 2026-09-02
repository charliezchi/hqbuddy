#include <stdio.h>
#include <inttypes.h>
#include "STAR.h"
#include "STAR_gpio.h"
#include "uart.h"
#include "ahb.h"

//LED2 GPIO0_0
#define LED2_PORT	STAR_GPIO0
#define LED2_PIN	GPIO_Pin_0
//LED3 GPIO0_1
#define LED3_PORT	STAR_GPIO0
#define LED3_PIN	GPIO_Pin_1

//LED开启
#define LED2_ON		GPIO_SetBit(LED2_PORT,LED2_PIN)
#define LED3_ON		GPIO_SetBit(LED3_PORT,LED3_PIN)

//LED关闭
#define LED2_OFF	GPIO_ResetBit(LED2_PORT,LED2_PIN)
#define LED3_OFF	GPIO_ResetBit(LED3_PORT,LED3_PIN)

void delay_ms(uint16_t dly)
{
	uint32_t i,j;
	for(i=0;i<dly;i++)
	{
		for(j=0;j<3000;j++);
	}
}

int main(void)
{	
	GPIO_DeInit(STAR_GPIO0);
	
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
	
	
	uart_init(115200);
	printf("STAR AHB test...\r\n");
	AHB_readWrite_test();
	while(1)
	{
		delay_ms(100);
	}
}
