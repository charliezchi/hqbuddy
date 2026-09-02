#ifndef __EXTINT_H
#define __EXTINT_H	 
#include "CM3DS_MPS2.h"
								  
//LED1-GPIO0_0
#define LED1_PORT	CM3DS_MPS2_GPIO0
#define LED1_PIN	GPIO_Pin_0

//LED2-GPIO0_1
#define LED2_PORT	CM3DS_MPS2_GPIO0
#define LED2_PIN	GPIO_Pin_1

//点亮LED
#define LED1_ON		GPIO_ResetBit(LED1_PORT,LED1_PIN)
#define LED2_ON		GPIO_ResetBit(LED2_PORT,LED2_PIN)

//熄灭LED
#define LED1_OFF	GPIO_SetBit(LED1_PORT,LED1_PIN)
#define LED2_OFF 	GPIO_SetBit(LED2_PORT,LED2_PIN)

void mcu_bsp(void);		 	

#endif

