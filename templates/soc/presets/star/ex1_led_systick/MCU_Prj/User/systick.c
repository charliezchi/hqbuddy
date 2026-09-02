#include "systick.h"

uint32_t TimingDelay = 0;

/**
* @brief 启动系统滴答定时器SysTick
* @param 无
* @retval 无
*/
void SysTick_Init(void)
{
	/* SystemFrequency / 1000 1ms 中断一次
	* SystemFrequency / 100000 10us 中断一次
	* SystemFrequency / 1000000 1us 中断一次
	*/
	if (SysTick_Config(SystemCoreClock / 1000)) {
	/* Capture error */
	while (1);
	}
}

/**
* @brief us 延时程序,10us 为一个单位
* @param
* @arg nTime: Delay_us( 1 ) 则实现的延时为1 * 10us = 10us
* @retval 无
*/
void Delay_ms(uint32_t nTime)
{
	TimingDelay = nTime;
	while (TimingDelay != 0);
}

void SysTick_Handler(void)
{
	if (TimingDelay != 0x00) 
	{
		TimingDelay--;
	}
}