#include "STAR.h"
#include "STAR_gpio.h"
#include "STAR_uart.h"
#include "STAR_rcc.h"

/*uart接收中断初始配置*/
static void uart_interrupt_init(UART_TypeDef *UARTx)
{
	/*使能接收中断*/
	UART_Interrupt_Config(UARTx, UART_RxInterrupt, ENABLE);
	
	if(UARTx ==STAR_UART0)
	{
		NVIC_ClearPendingIRQ(UART0_IRQn);
		NVIC_EnableIRQ(UART0_IRQn);
	}
	else if(UARTx ==STAR_UART1)
	{
		NVIC_ClearPendingIRQ(UART1_IRQn);
		NVIC_EnableIRQ(UART1_IRQn);
	}
	else
	{
		NVIC_ClearPendingIRQ(UART2_IRQn);
		NVIC_EnableIRQ(UART2_IRQn);
	}
	
}

/*uart初始化配置*/
static void uartx_init(UART_TypeDef *UARTx,uint32_t BundRate)
{
	UART_InitTypeDef  UART_InitStructure;
	
	UART_DeInit(UARTx);
	
	/*将对应的GPIO管脚复用为对应UART的收发管脚*/
	if(UARTx ==STAR_UART0)
	{
		GPIO_AF_Config(STAR_GPIO0, GPIO_AF_USART0_RXD, ENABLE); //GPIO[2]
		GPIO_AF_Config(STAR_GPIO0, GPIO_AF_USART0_TXD, ENABLE); //GPIO[3]
	}
	else if(UARTx ==STAR_UART1)
	{
		GPIO_AF_Config(STAR_GPIO0, GPIO_AF_USART1_RXD, ENABLE); //GPIO[4]
		GPIO_AF_Config(STAR_GPIO0, GPIO_AF_USART1_TXD, ENABLE); //GPIO[5]
	}
	else
	{
		GPIO_AF_Config(STAR_GPIO0, GPIO_AF_USART2_RXD, ENABLE); //GPIO[22]
		GPIO_AF_Config(STAR_GPIO0, GPIO_AF_USART2_TXD, ENABLE); //GPIO[23]
	}
	
	UART_InitStructure.UART_BundRate = BundRate; 
	/*收发使能*/
	UART_InitStructure.UART_CTRL =  UART_CTRL_TxEnable | UART_CTRL_RxEnable;	
	UART_Init( UARTx, &UART_InitStructure);	
	
	/*接收中断配置*/
	uart_interrupt_init(UARTx);
}

void uart_init(uint32_t BundRate)
{
	UART_TypeDef *UARTx;
	
	UARTx = STAR_UART0;
	uartx_init(UARTx,BundRate);
}

/*uart0 中断处理函数*/
void UART0_Handler(void)
{
	uint8_t ch;
	
	if(UART_Get_Interrupt_Status(STAR_UART0,UART_RxInterrupt)==SET)	//接收中断
	{
		/*读取接收到的数据*/
		ch=UART_ReceiveData(STAR_UART0);
		/*将接收到的数据发送回去*/
		UART_SendData(STAR_UART0,ch);
		/*清除中断*/
		UART_Interrupt_Clear(STAR_UART0, UART_RxInterrupt);
	}
}

/*uart1 中断处理函数*/
void UART1_Handler(void)
{
	uint8_t ch;
	
	if(UART_Get_Interrupt_Status(STAR_UART1,UART_RxInterrupt)==SET)	//接收中断
	{
		/*读取接收到的数据*/
		ch=UART_ReceiveData(STAR_UART1);
		/*将接收到的数据发送回去*/
		UART_SendData(STAR_UART1,ch);
		/*清除中断*/
		UART_Interrupt_Clear(STAR_UART1, UART_RxInterrupt);
	}	
}

/*uart2 中断处理函数*/
void UART2_Handler(void)
{
	uint8_t ch;
	
	if(UART_Get_Interrupt_Status(STAR_UART2,UART_RxInterrupt)==SET)	//接收中断
	{
		/*读取接收到的数据*/
		ch=UART_ReceiveData(STAR_UART2);
		/*将接收到的数据发送回去*/
		UART_SendData(STAR_UART2,ch);
		/*清除中断*/
		UART_Interrupt_Clear(STAR_UART2, UART_RxInterrupt);
	}
	
}

