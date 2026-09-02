#include "STAR.h"
#include "STAR_gpio.h"
#include "STAR_rcc.h"


/*GPIO2中断初始化*/
void gpio2_interrupt_init(void)
{	
	/*GPIO2设置为低电平触发*/
	GPIO_Interrupt_Config(STAR_GPIO0,GPIO_Pin_2,Bit_LOWLEVEL,Interrupt_ENABLE);
	NVIC_ClearPendingIRQ(PORT0_2_IRQn);
	NVIC_EnableIRQ(PORT0_2_IRQn);
}

/*GPIO2中断处理函数*/
void PORT0_2_Handler(void)
{
	/*LED2 ON*/
	GPIO_SetBit(STAR_GPIO0, GPIO_Pin_0);
	//清除中断
	GPIO_Interrupt_Clear(STAR_GPIO0,GPIO_Pin_2);	
	NVIC_ClearPendingIRQ(PORT0_2_IRQn);	
}





