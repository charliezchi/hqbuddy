#include "CM3DS_gpio.h"
#include "CM3DS_uart.h"	
#include "CM3DS_rcc.h"
#include "CM3DS_uart.h"	
#include "CM3DS_MPS2.h"
#include "misc.h"
#include <stdio.h>
#include "extint.h"

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

/*????*/
void delay_ms(unsigned int ms)
{
	unsigned int i, j;
	for (i = 0; i <= ms; i++)
	{
		for(j= 0; j <= 3000; j++);
	}
}

/*外部中断0初始化设置
 中断源为来自FPGA的KEY1 CM3的外部中断EXTI只有高电平触发 不支持其他触发方式
*/
void extint0_init(void)
{	
	NVIC_InitTypeDef nvic_init_t;
	
	NVIC_ClearPendingIRQ(EXT0_IRQn);  //clear NVIC pending interrupts
	
	/*中断优先级设置*/
	nvic_init_t.NVIC_IRQChannel = EXT0_IRQn;
	nvic_init_t.NVIC_IRQChannelPreemptionPriority = 0;	//抢占优先级
	nvic_init_t.NVIC_IRQChannelSubPriority = 0;			//响应优先级
	nvic_init_t.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&nvic_init_t);
	
	NVIC_EnableIRQ(EXT0_IRQn);
}

void extint15_init(void)
{	
	NVIC_InitTypeDef nvic_init_t;
	
	NVIC_ClearPendingIRQ(EXT15_IRQn);                   //clear NVIC pending interrupts
	
	/*中断优先级设置*/
	nvic_init_t.NVIC_IRQChannel = EXT15_IRQn;
	nvic_init_t.NVIC_IRQChannelPreemptionPriority = 0;	//抢占优先级
	nvic_init_t.NVIC_IRQChannelSubPriority = 0;	//响应优先级
	nvic_init_t.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&nvic_init_t);
	
	NVIC_EnableIRQ(EXT15_IRQn);
}

void EXT0_Handler(void)
{
	GPIO_TogglePin(LED2_PORT,LED2_PIN);
	GPIO_TogglePin(LED3_PORT,LED3_PIN);
	printf("EXT0_Handler\r\n");
	
	NVIC_ClearPendingIRQ(EXT0_IRQn);		//清除中断标志		
}

void EXT15_Handler(void)
{
	GPIO_TogglePin(LED2_PORT,LED2_PIN);
	GPIO_TogglePin(LED3_PORT,LED3_PIN);
	printf("EXT15_Handler\r\n");
	
	NVIC_ClearPendingIRQ(EXT15_IRQn);		//清除中断标志	
}

/*uart0初始化*/
void uart0_init(uint32_t BundRate)
{
	UART_InitTypeDef  UART_InitStructure; 
	
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_2,GPIO_Mode_AF);
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART0_RXD, ENABLE); 					//GPIO[2]
	
	GPIO_Mode_Set(CM3DS_MPS2_GPIO0,GPIO_Pin_3,GPIO_Mode_AF);
	GPIO_AF_Config( CM3DS_MPS2_GPIO0, GPIO_AF_USART0_TXD, ENABLE); 					//GPIO[3]
	
	UART_InitStructure.UART_BundRate = BundRate;
	UART_InitStructure.UART_CTRL =  UART_CTRL_TxEnable | UART_CTRL_RxEnable;	
	
	UART_Init( CM3DS_MPS2_UART0, &UART_InitStructure);	
	
}


void mcu_bsp(void)
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
	
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2);
	uart0_init(115200);
	extint0_init();
}

