#include "uart.h"
#include "CM3DS_rcc.h"
#include "CM3DS_gpio.h"
#include "CM3DS_uart.h"	
#include "CM3DS_MPS2.h"	
#include <stdio.h>

void uart0_init(uint32_t BundRate)
{
	UART_InitTypeDef  UART_InitStructure; 
	
	UART_DeInit(CM3DS_MPS2_UART0);
	
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_2,GPIO_Mode_AF);
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART0_RXD, ENABLE); 					//GPIO[2]
	
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_3,GPIO_Mode_AF);
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART0_TXD, ENABLE); 					//GPIO[3]
	
	UART_InitStructure.UART_BundRate = BundRate;
	UART_InitStructure.UART_CTRL =  UART_CTRL_TxEnable | UART_CTRL_RxEnable;	
	
	UART_Init( CM3DS_MPS2_UART0, &UART_InitStructure);	
	
}

