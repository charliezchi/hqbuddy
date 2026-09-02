#include "CM3DS_MPS2.h"
#include "core_cm3.h"
#include "sysTick.h"

#define TICKS_PER_SEC 1000 //每秒多少个Tick
uint32_t TimingDelay = 0;

/*sysTick初始化*/
void SysTick_Init(void) 
{	
	/* SystemFrequency / 1000 1ms 中断一次
	* SystemFrequency / 100000 10us 中断一次
	* SystemFrequency / 1000000 1us 中断一次
	*/
	SysTick_Config(SystemCoreClock/TICKS_PER_SEC);
}

/**
* @brief us 延时程序,1ms 为一个单位
* @param
* @arg nTime: Delay_ms( 1 ) 则实现的延时为1 * 1ms = 1ms
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


