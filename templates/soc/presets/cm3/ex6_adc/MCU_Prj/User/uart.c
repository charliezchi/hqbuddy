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
	
	//uart_irq_init();
}
	
void uart1_init(uint32_t BundRate)
{
	UART_InitTypeDef  UART_InitStructure; 

	UART_DeInit(CM3DS_MPS2_UART1);
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_4,GPIO_Mode_AF);
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART1_RXD, ENABLE); 					//GPIO[4]
	
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_5,GPIO_Mode_AF);
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART1_TXD, ENABLE); 					//GPIO[5]
	
	UART_InitStructure.UART_BundRate = BundRate;
	UART_InitStructure.UART_CTRL =  UART_CTRL_TxEnable | UART_CTRL_RxEnable;	
	UART_Init( CM3DS_MPS2_UART1, &UART_InitStructure);	
}
	
void uart_irq_init(void)
{
	UART_Interrupt_Config(CM3DS_MPS2_UART0, UART_RxInterrupt, ENABLE);
	NVIC_ClearPendingIRQ(UART0_IRQn);
	NVIC_EnableIRQ(UART0_IRQn);
} 
	
void UART0_Handler(void)
{
	uint8_t dat;
	if(UART_Get_Interrupt_Status(CM3DS_MPS2_UART0,UART_RxInterrupt)==SET)
	{
		dat = UART_ReceiveData(CM3DS_MPS2_UART0);
		//UART_SendData(CM3DS_MPS2_UART0,dat);
		UART_Interrupt_Clear(CM3DS_MPS2_UART0, UART_RxInterrupt);//clear uart irq
	}
	
}

