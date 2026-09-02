#include "CM3DS_gpio.h"
#include "CM3DS_MPS2.h"


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

//SW2
#define KEY_SW2_PORT 	CM3DS_MPS2_GPIO0
#define KEY_SW2_PIN 	GPIO_Pin_2


void delay_ms(uint16_t dly)
{
	uint32_t i,j;
	for(i=0;i<dly;i++)
	{
		for(j=0;j<1000;j++);
	}
}

/*中断初始化配置*/
void gpio_int_init(void)
{	
	/*设置GPIO0_2的中断类型为低电平触发，且使能该中断*/
	GPIO_Interrupt_Config(KEY_SW2_PORT,KEY_SW2_PIN,Bit_LOWLEVEL,Interrupt_ENABLE);
	
	NVIC_ClearPendingIRQ(PORT0_2_IRQn);
	
	NVIC_EnableIRQ(PORT0_2_IRQn);
}	

/*中断处理函数*/
void PORT0_2_Handler(void)
{
	
	LED2_ON;
	LED3_ON;
	/*清除当前中断请求*/
	GPIO_Interrupt_Clear(KEY_SW2_PORT,KEY_SW2_PIN);		
}


int main(void)
{	
	uint8_t keyval;
	GPIO_DeInit(CM3DS_MPS2_GPIO0);
	
	/*LED GPIO模式设置*/
	GPIO_Mode_Set(LED2_PORT,LED2_PIN,GPIO_Mode_Output);
	GPIO_Mode_Set(LED3_PORT,LED3_PIN,GPIO_Mode_Output);
	
	gpio_int_init();
	while(1)
	{
		LED2_OFF;
		LED3_OFF;
	}
}


