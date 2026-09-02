#include "uart.h"
#include "CM3DS_rcc.h"
#include "CM3DS_gpio.h"
#include "CM3DS_uart.h"	
#include "CM3DS_MPS2.h"	
#include <stdio.h>

/*uart0 中断初始化*/
void uart0_irq_init(void)
{
	UART_Interrupt_Config(CM3DS_MPS2_UART0, UART_RxInterrupt, ENABLE);
	NVIC_ClearPendingIRQ(UART0_IRQn);
	NVIC_EnableIRQ(UART0_IRQn);
} 

/*uart0初始化*/
void uart0_init(uint32_t BundRate)
{
	UART_InitTypeDef  UART_InitStructure; 
	
	UART_DeInit(CM3DS_MPS2_UART0);
	
	/*收发管脚设置*/
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_2,GPIO_Mode_AF);		//GPIO[2] USART0_RX Pin
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART0_RXD, ENABLE); 					
	
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_3,GPIO_Mode_AF);		//GPIO[3] USART0_TX Pin
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART0_TXD, ENABLE); 					
	
	UART_InitStructure.UART_BundRate = BundRate;
	UART_InitStructure.UART_CTRL =  UART_CTRL_TxEnable | UART_CTRL_RxEnable;	
	
	UART_Init( CM3DS_MPS2_UART0, &UART_InitStructure);	
	
	/*中断设置*/
	uart0_irq_init();
}

/*uart1初始化*/
void uart1_init(uint32_t BundRate)
{
	UART_InitTypeDef  UART_InitStructure; 

	UART_DeInit(CM3DS_MPS2_UART1);
	/*收发管脚设置*/
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_4,GPIO_Mode_AF);		//GPIO[4]	USART1_RX Pin
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART1_RXD, ENABLE); 					
	
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_5,GPIO_Mode_AF);		//GPIO[5]	USART1_TX Pin
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART1_TXD, ENABLE); 					
	
	UART_InitStructure.UART_BundRate = BundRate;  
	UART_InitStructure.UART_CTRL =  UART_CTRL_TxEnable | UART_CTRL_RxEnable;
	
	UART_Init( CM3DS_MPS2_UART1, &UART_InitStructure);	
}

/*UART0中断服务函数*/
void UART0_Handler(void)
{
	uint8_t dat;
	if(UART_Get_Interrupt_Status(CM3DS_MPS2_UART0,UART_RxInterrupt)==SET)
	{
		dat = UART_ReceiveData(CM3DS_MPS2_UART0);
		UART_SendData(CM3DS_MPS2_UART0,dat);		//将收到的数据发送回去 
		UART_Interrupt_Clear(CM3DS_MPS2_UART0, UART_RxInterrupt);//clear uart irq
	}
	
}

