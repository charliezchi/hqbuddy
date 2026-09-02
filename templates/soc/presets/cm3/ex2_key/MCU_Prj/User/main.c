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

int main(void)
{	
	uint8_t keyval;
	GPIO_DeInit(CM3DS_MPS2_GPIO0);
	
	/*LED GPIO模式设置*/
	GPIO_Mode_Set(LED2_PORT,LED2_PIN,GPIO_Mode_Output);
	GPIO_Mode_Set(LED3_PORT,LED3_PIN,GPIO_Mode_Output);
	
	while(1)
	{
		keyval = GPIO_ReadInputBit(KEY_SW2_PORT,KEY_SW2_PIN); //读取按键对应GPIO的电平
		
		if(keyval==Bit_RESET)
		{
			LED2_ON;
			LED3_ON;
		}
		else
		{
			LED2_OFF;
			LED3_OFF;
		}
	}
}


