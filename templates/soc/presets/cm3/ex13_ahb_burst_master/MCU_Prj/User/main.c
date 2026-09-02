#include "CM3DS_MPS2.h"
#include "CM3DS_gpio.h"
#include "CM3DS_uart.h"
#include "CM3DS_dma.h"	
#include "DMA_AHB.h"	
#include "uart.h"
#include <stdio.h>
#include <string.h>

//LED2 GPIO0_0
#define LED2_PORT	CM3DS_MPS2_GPIO0
#define LED2_PIN	GPIO_Pin_0
//LED3 GPIO0_1
#define LED3_PORT	CM3DS_MPS2_GPIO0
#define LED3_PIN	GPIO_Pin_1

//LED??
#define LED2_ON		GPIO_ResetBit(LED2_PORT,LED2_PIN)
#define LED3_ON		GPIO_ResetBit(LED3_PORT,LED3_PIN)

//LED??
#define LED2_OFF	GPIO_SetBit(LED2_PORT,LED2_PIN)
#define LED3_OFF	GPIO_SetBit(LED3_PORT,LED3_PIN)

void delay_ms(unsigned int ms)
{
	unsigned int i, j;
	for (i = 0; i <= ms; i++)
	{
		for(j= 0; j <= 3000; j++);
	}
}


int main(int argc, char *argv[])
{	
	GPIO_DeInit(CM3DS_MPS2_GPIO0);
	
	/*LED GPIO????*/
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
	DMA_BURST_WRITE_AHB();
	delay_ms(200);
	DMA_BURST_READ_AHB();
	

	while(1)
	{
		printf("run...\r\n");
		delay_ms(2000);
	}
}



