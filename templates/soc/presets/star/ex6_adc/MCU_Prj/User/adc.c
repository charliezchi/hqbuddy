#include "STAR_rcc.h"
#include "STAR_gpio.h"
#include "STAR.h"
#include "STAR_adc.h"
#include "adc.h"
#include <stdio.h>
#include "systick.h"

uint32_t ADC_buf[32];
volatile uint16_t lower;
volatile uint16_t upper;
volatile uint8_t flag=0;

ADC_TypeDef* ADCSel;


/*ADC中断配置*/
void ADC_Interrupt_Init(ADC_TypeDef* ADCx)
{
	NVIC_ClearPendingIRQ(ADC_IRQn);
	NVIC_EnableIRQ(ADC_IRQn);
	ADC_EOCInterrupt_Config(ADCx, ENABLE);//使能ADC中断
} 

/*ADC初始化配置*/
void ADC_adc_Init(ADC_TypeDef* ADCx)
{
	ADC_InitTypeDef  ADC_InitStruct;
	
	ADC_DeInit(ADCx);
	
	ADC_InitStruct.ADC_RefVol_Sel 	= ADC_REF_VOL_INTERIOR;	//参考电平选择
	ADC_InitStruct.ADC_PDn 			= ADC_ACTIVE;			//ADC PowerDown Disable
	ADC_InitStruct.ADC_ClkPreDiv 	= ADC_ClkPreDiv_48;		//时钟分频
	ADC_InitStruct.ADC_ConversionMode  = ADC_ConversionMode_Continuous;		//连续转换
	ADC_InitStruct.ADC_DataBufEnable   = ADC_DataBufEnable_Enable;			//数据缓存使能
	ADC_InitStruct.ADC_ExternalTrigConvEnable  = ADC_ExternalTrigConvEnable_Disable;//外部触发关闭
	ADC_InitStruct.ADC_ExternalEventSel        = ADC_ExternalEventSel_Timer0;		//外部事件
	ADC_InitStruct.ADC_DataAlign  		= ADC_DataAlign_Right;		//数据右对齐
	ADC_InitStruct.ADC_ScanModeEanbel   = ADC_ScanModeEanbel_Disable;//启动扫描模式		
	
	ADC_Init(ADCx,&ADC_InitStruct);
	
	ADC_Interrupt_Init(ADCx);
	
	ADC_Channel_Select(ADCx,ADC_Channel_0);	//选择ADC通道
	
	ADC_Cmd(ADCx,ENABLE);	//使能ADC并开始转换
}


/*ADC中断处理函数*/
void ADC_Handler(void)
{	
	flag=1;
	/*ADC转换值存储位置判断*/
	if(ADC_DataBufEnable_Get(ADCSel) )
	{	
		ADC_GetValueFromDBR(ADCSel,ADC_buf); //从ADC_DBR寄存器读取采样值	
	}
	else
	{	
		ADC_buf[0]=ADC_GetValueFromDR(ADCSel);
	}
	
	ADC_EOCFlag_Clear(ADCSel);
	
	if(ADC_DataBufOVRFlag_Get(ADCSel))
	{
		ADC_DataBufOVRFlag_Clear(ADCSel);
	}
}

/*打印ADC采样数据*/
void ADC_printf(void)
{
	uint8_t i;
	while(flag==0);
	if(ADC_DataBufEnable_Get(ADCSel)==SET )
	{
		for(i=0;i<8;i++) 
		{
			lower = ADC_buf[i];
			upper = ADC_buf[i]>>16;
			printf("ADC_buf[%d]_upper=%x;ADC_buf[%d]_lower=%x.\r\n",i,upper,i,lower);
		}
		printf("\n");
	}
	else
	{
		printf("ADC_Value=%x.\r\n",ADC_buf[0]);
	}
	flag=0;
}


void ADC_test(void)
{
	ADCSel = STAR_ADC0;
	ADC_adc_Init(ADCSel);
	
	while(1)
	{		
		ADC_printf();
		Delay_ms(1000);
	}
}
