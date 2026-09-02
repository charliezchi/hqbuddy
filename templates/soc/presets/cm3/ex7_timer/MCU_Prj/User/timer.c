#include "CM3DS_timer.h"
#include "CM3DS_rcc.h"
#include "timer.h"
#include "CM3DS_MPS2.h"
#include "CM3DS_gpio.h"

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



/*定时器初始化设置*/
void timer_init(void)
{	
	TIMER_TypeDef* timer;
	TIM_InitTypeDef TIM_InitStruct;
	
	timer = CM3DS_MPS2_TIMER0;
	
	/*初始化设置*/
	TIM_DeInit(timer);
	TIM_InitStruct.TIM_InterruptEnable = TIM_Interrupt_Enable; //使能中断
	TIM_InitStruct.TIM_SelExtInputAsClk = TIM_Sel_PclkAsClk; 
	TIM_InitStruct.TIM_SelExtInputAsEn = TIM_Sel_SoftSetAsEn;
	TIM_InitStruct.TIM_Value  = 25000000; //定时时间设为1秒 定时器时钟PCLK=25M，定时1秒 定时器装载值为25000000
	TIM_InitStruct.TIM_Reload = 25000000; 
	 
	TIM_Init(timer, &TIM_InitStruct);
	
	/*中断设置*/
	if(timer==CM3DS_MPS2_TIMER0)
	{
		NVIC_ClearPendingIRQ(TIMER0_IRQn);
		NVIC_EnableIRQ(TIMER0_IRQn);
	}
	else
	{
		NVIC_ClearPendingIRQ(TIMER1_IRQn);
		NVIC_EnableIRQ(TIMER1_IRQn);
	}
	
	
	TIM_InterruptFlag_Clear(timer);
	
	TIM_Enable(timer,ENABLE);
}


/*定时器0中断处理函数*/
void TIMER0_Handler(void)
{
	GPIO_TogglePin(LED2_PORT,LED2_PIN);
	GPIO_TogglePin(LED3_PORT,LED3_PIN);
	//清除中断
	TIM_InterruptFlag_Clear(CM3DS_MPS2_TIMER0);
}

/*定时器1中断处理函数*/
void TIMER1_Handler(void)
{
	GPIO_TogglePin(LED2_PORT,LED2_PIN);
	GPIO_TogglePin(LED3_PORT,LED3_PIN);
	//清除中断
	TIM_InterruptFlag_Clear(CM3DS_MPS2_TIMER0);
}

void Timer_Test(void)
{
	/*LED指示灯管脚初始化*/
	GPIO_DeInit(CM3DS_MPS2_GPIO0);
	GPIO_Mode_Set(LED2_PORT,LED2_PIN,GPIO_Mode_Output);
	GPIO_Mode_Set(LED3_PORT,LED3_PIN,GPIO_Mode_Output);
	
	LED2_OFF;
	LED3_OFF;
	
	/*定时器初始化*/
	timer_init();
}

