#include "STAR_dualtimer.h"
#include "STAR_rcc.h"
#include "Dualtimer.h"
#include "STAR.h"
#include "STAR_gpio.h"

//LED2 GPIO0_0,LED3 GPIO0_1
#define LED2_PORT	STAR_GPIO0
#define LED2_PIN	GPIO_Pin_0
#define LED3_PORT	STAR_GPIO0
#define LED3_PIN	GPIO_Pin_1

//LED开启
#define LED2_ON		GPIO_SetBit(LED2_PORT,LED2_PIN)
#define LED3_ON		GPIO_SetBit(LED3_PORT,LED3_PIN)

//LED关闭
#define LED2_OFF	GPIO_ResetBit(LED2_PORT,LED2_PIN)
#define LED3_OFF	GPIO_ResetBit(LED3_PORT,LED3_PIN)


/*双定时器初始配置*/
void DualTimer_Init(void)
{
	DTIM_InitTypeDef DTIM_InitStr;
	DUALTIMER_TypeDef* DUALTIMERx;
	
	DUALTIMERx = STAR_DUALTIMER0;
	
	DTIM_DeInit(DUALTIMERx);
	/*DualTimer Timer1设置 */
	DTIM_InitStr.DTIM_Mode = DTIM_Mode_Periodic;				//周期模式
	DTIM_InitStr.DTIM_InterruptEnable = DTIM_Interrupt_Enable;	//中断使能
	DTIM_InitStr.DTIM_ClkDiv = DTIM_ClkDiv_1;					//时钟1分频
	DTIM_InitStr.DTIM_CounterSize = DTIM_CounterSize_32bit;		//32位计数器模式
	DTIM_InitStr.DTIM_LoadVal = 25000000;						//Timer1定时时间设置为1秒，PCLK时钟为25M, 定时1秒 加载值设置为25000000
	DTIM_Init(DUALTIMERx,DTIM_TIMER1,&DTIM_InitStr);
	
	/*DualTimer Timer2设置 */
	DTIM_InitStr.DTIM_LoadVal = 50000000;						//Timer2定时时间设置为2秒，PCLK时钟为25M, 定时2秒 加载值设置为50000000
	DTIM_Init(DUALTIMERx,DTIM_TIMER2,&DTIM_InitStr);
	
	//DTIM_SetBGLoad(DUALTIMERx,DTIM_TIMER1,25000000);
	
	/*中断使能*/
	if(DUALTIMERx == STAR_DUALTIMER0)
	{
		NVIC_ClearPendingIRQ(DUALTIMER0_IRQn);
		NVIC_EnableIRQ(DUALTIMER0_IRQn);
	}
	else
	{
		NVIC_ClearPendingIRQ(DUALTIMER1_IRQn);
		NVIC_EnableIRQ(DUALTIMER1_IRQn);
	}
	
	DTIM_InterruptFlag_Clear(DUALTIMERx,DTIM_TIMER1);
	DTIM_InterruptFlag_Clear(DUALTIMERx,DTIM_TIMER2);
	
	/*使能DualTimer，使其开始工作*/
	DTIM_Enable(DUALTIMERx,DTIM_TIMER1,ENABLE);
	DTIM_Enable(DUALTIMERx,DTIM_TIMER2,ENABLE);
}

//DualTimer0 中断处理函数
void DUALTIMER0_Handler(void)
{
	if(DTIM_InterruptStatus_Get(STAR_DUALTIMER0,DTIM_TIMER1))
	{
		GPIO_TogglePin(LED2_PORT,LED2_PIN);
		DTIM_InterruptFlag_Clear(STAR_DUALTIMER0,DTIM_TIMER1);
	}
	
	if(DTIM_InterruptStatus_Get(STAR_DUALTIMER0,DTIM_TIMER2))
	{
		GPIO_TogglePin(LED3_PORT,LED3_PIN);
		DTIM_InterruptFlag_Clear(STAR_DUALTIMER0,DTIM_TIMER2);
	}
}

//DualTimer1 中断处理函数
void DUALTIMER1_Handler(void)
{
	if(DTIM_InterruptStatus_Get(STAR_DUALTIMER1,DTIM_TIMER1))
	{
		GPIO_TogglePin(LED2_PORT,LED2_PIN);
		DTIM_InterruptFlag_Clear(STAR_DUALTIMER1,DTIM_TIMER1);
	}
	
	if(DTIM_InterruptStatus_Get(STAR_DUALTIMER1,DTIM_TIMER2))
	{
		GPIO_TogglePin(LED3_PORT,LED3_PIN);
		DTIM_InterruptFlag_Clear(STAR_DUALTIMER1,DTIM_TIMER2);
	}
}


void DualTimer_Test(void)
{
	/*LED指示灯管脚设置*/
	GPIO_DeInit(STAR_GPIO0);
	GPIO_Mode_Set(LED2_PORT,LED2_PIN,GPIO_Mode_Output);
	GPIO_Mode_Set(LED3_PORT,LED3_PIN,GPIO_Mode_Output);
	
	LED2_OFF;
	LED3_OFF;
	
	/*双定时器初始化*/
	DualTimer_Init();
	
	while(1);
}
