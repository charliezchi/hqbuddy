#include "CM3DS_rcc.h"
#include "CM3DS_gpio.h"
#include "CM3DS_MPS2.h"
#include "CM3DS_adc.h"
#include "ADC.h"
#include "uart.h"
#include "CM3DS_uart.h"	
#include "CM3_retarget.h"
#include <stdio.h>

uint16_t data_dr[6];
uint32_t ADC_buf[8];
uint16_t lower;
uint16_t upper;
uint8_t flag=0;

/*ADC中断配置*/
void ADC_Interrupt_Init(void)
{
	NVIC_ClearPendingIRQ(ADC_IRQn);
	NVIC_EnableIRQ(ADC_IRQn);
	ADC_EOCInterrupt_Config(ENABLE);//使能ADC EOC中断
} 


/*ADC初始化配置*/
void adc_init(void)
{
	ADC_InitTypeDef  ADC_InitStruct;
	
	ADC_DeInit();
	
	ADC_InitStruct.ADC_ClkPreDiv	= ADC_ClkPreDiv_48;								//时钟分频
	ADC_InitStruct.ADC_ConversionMode  = ADC_ConversionMode_Continuous;				//连续转换
	ADC_InitStruct.ADC_DataBufEnable    = ADC_DataBufEnable_Enable;				//数据缓存使能 
	ADC_InitStruct.ADC_ExternalTrigConvEnable  = ADC_ExternalTrigConvEnable_Disable;	//外部触发关闭
	ADC_InitStruct.ADC_ExternalEventSel        = ADC_ExternalEventSel_Timer0;	//外部事件
	ADC_InitStruct.ADC_DataAlign     = ADC_DataAlign_Right;						//数据右对齐
	ADC_InitStruct.ADC_ScanModeEanbel   = ADC_ScanModeEanbel_Enable;			//启动扫描模式
	ADC_Init(&ADC_InitStruct);
	
	ADC_Interrupt_Init();
	
	ADC_Channel_Select(ADC_Channel_1);	//选择ADC通道
	
	
	ADC_Cmd(ENABLE);	//使能ADC并开始转换
}



//ADC中断处理函数
void ADC_Handler(void)
{	
	uint8_t i;
	
	/*ADC转换值存储位置判断*/
	if(ADC_DataBufEnable_Get()==SET )
	{	
		ADC_GetValueFromDBR(ADC_buf); 		//从ADC_DBR寄存器读取采样值
	}
	else
	{	
		for(i=0;i<2;i++)
		{
			data_dr[i] = ADC_GetValueFromDR();//从ADC_DR寄存器读取采样值
		}
	}
	
	flag=1;	
	
	ADC_EOCFlag_Clear();
	
	if(ADC_DataBufOVRFlag_Get())
	{
		ADC_DataBufOVRFlag_Clear();
	}
}
/*打印ADC采样数据*/
void ADC_printf(void)
{
	uint8_t i;
	
	while(flag==0);
	if(ADC_DataBufEnable_Get()==SET )
	{
		for(i=0;i<1;i++) //只打印输入通道0和输入通道1的采样值
		{
			lower = ADC_buf[i];
			upper = ADC_buf[i]>>16;
			printf("ADC_IN1_Value=%d;ADC_IN0_Value=%d.\r\n",upper,lower);
		}
	}
	else
	{
		printf("ADC_Value1=%d;ADC_Value2=%d.\r\n",data_dr[0],data_dr[1]);
	}
	printf("\n");	
	flag=0;
}

														  
static void delay_1ms(unsigned int ms)
{
	unsigned int i, j;
	for (i = 0; i <= ms; i++)
	{
		for(j= 0; j <= 3000; j++);
	}
}


void ADC_test(void)
{
	adc_init();
	
	while(1)
	{		
		ADC_printf();
 		delay_1ms(1000);
	}
}
