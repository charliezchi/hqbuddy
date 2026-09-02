#include "STAR_gpio.h"
#include "STAR_rcc.h"
#include "STAR.h"
#include "STAR_uart.h"
#include "misc.h"
#include <stdio.h>
#include "extint.h"

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


/*外部中断0初始化设置
 中断源为来自FPGA的SW8 STAR的外部中断EXTI只有高电平触发 不支持其他触发方式
*/
void extint0_init(void)
{	
	NVIC_InitTypeDef nvic_init_t;
	
	NVIC_ClearPendingIRQ(EXT0_IRQn);	//clear NVIC pending interrupts
	
	/*中断优先级设置*/
	nvic_init_t.NVIC_IRQChannel = EXT0_IRQn;
	nvic_init_t.NVIC_IRQChannelPreemptionPriority = 0;	//抢占优先级
	nvic_init_t.NVIC_IRQChannelSubPriority = 0;	//响应优先级
	nvic_init_t.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&nvic_init_t);
	
	NVIC_EnableIRQ(EXT0_IRQn);
}

void extint15_init(void)
{	
	NVIC_InitTypeDef nvic_init_t;
	
	NVIC_ClearPendingIRQ(EXT15_IRQn);	//clear NVIC pending interrupts
	
	/*中断优先级设置*/
	nvic_init_t.NVIC_IRQChannel = EXT15_IRQn;
	nvic_init_t.NVIC_IRQChannelPreemptionPriority = 0;	//抢占优先级
	nvic_init_t.NVIC_IRQChannelSubPriority = 1;	//响应优先级
	nvic_init_t.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&nvic_init_t);
	
	NVIC_EnableIRQ(EXT15_IRQn);
}

void EXT0_Handler(void)
{
	/*点亮/熄灭LED2*/
	GPIO_TogglePin(LED2_PORT, LED2_PIN);
	printf("EXT0_Handler\r\n");
	/*清除中断标志*/
	NVIC_ClearPendingIRQ(EXT0_IRQn);		
}

void EXT15_Handler(void)
{
	/*点亮/熄灭LED3*/
	GPIO_TogglePin(LED3_PORT, LED3_PIN);
	printf("EXT15_Handler\r\n");
	/*清除中断标志*/
	NVIC_ClearPendingIRQ(EXT15_IRQn);		
}

/*uart0初始化配置*/
void uart0_init(uint32_t BundRate)
{
	UART_InitTypeDef  UART_InitStructure;
	
	UART_DeInit(STAR_UART0);
	
	/*将对应的GPIO管脚复用为对应UART的收发管脚*/
	GPIO_Mode_Set(STAR_GPIO0,GPIO_Pin_2,GPIO_Mode_AF);
	GPIO_AF_Config(STAR_GPIO0, GPIO_AF_USART0_RXD, ENABLE); //GPIO[2]
	
	GPIO_Mode_Set(STAR_GPIO0,GPIO_Pin_3,GPIO_Mode_AF);
	GPIO_AF_Config(STAR_GPIO0, GPIO_AF_USART0_TXD, ENABLE); //GPIO[3]
	
	UART_InitStructure.UART_BundRate = BundRate; 
	/*收发使能*/
	UART_InitStructure.UART_CTRL =  UART_CTRL_TxEnable | UART_CTRL_RxEnable;
	
	UART_Init(STAR_UART0,&UART_InitStructure);	
}

void mcu_bsp(void)
{
	GPIO_DeInit(STAR_GPIO0);
	
	/*LED GPIO模式设置*/
	GPIO_Mode_Set(LED2_PORT,LED2_PIN,GPIO_Mode_Output);
	GPIO_Mode_Set(LED3_PORT,LED3_PIN,GPIO_Mode_Output);
	
	/*LED2 LED3 OFF*/
	LED2_OFF;
	LED3_OFF;
	
	
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2);
	uart0_init(115200);
	extint0_init();
}

