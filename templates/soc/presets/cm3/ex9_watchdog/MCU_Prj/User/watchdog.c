#include "CM3DS_gpio.h"
#include "CM3DS_MPS2.h"
#include "CM3DS_watchdog.h"
#include "watchdog.h"

/*看门狗初始化*/
void watchdog_init(void)
{
	WatchDog_DeInit();
	
	WatchDog_Unlock();	//解锁看门狗
	WatchDog_Set_Counter(50000000);	//设置看门狗加载值 设置为为50000000(2s内就要喂狗,PCLK=25M)
	WatchDog_Config(WDG_RST_Output_Enable,WDG_CNT_INT_Enable);	//使能开门狗
	WatchDog_Lock();	//锁定看门狗
}	

/*看门狗中断服务函数*/
void NMI_Handler(void)
{
	//LED2亮灭控制
	GPIO_TogglePin(CM3DS_MPS2_GPIO0, GPIO_Pin_0);
	
	/*需要注意：看门狗计数器到0后产生中断，计数器会重新加载计数值，计数器再次到0后才会复位；
	  如果产生中断后就清除了中断就不会再复位了*/
	//WatchDog_Interrupt_Clear();	//清除中断 
}

/*看门狗喂狗函数*/
void wdog_feed(uint32_t reload)
{
	WatchDog_Unlock();
	WatchDog_Set_Counter(reload); //重新设置reload值进行喂狗
	WatchDog_Lock();
}

void watchdog_test(void)
{
	uint32_t loadnum;
	
	watchdog_init();
	
	while(1)
	{
		loadnum=WatchDog_Get_CurrentCounter(); //获取看门狗当前计数值，如果计数值快要为0 则重新喂狗，在看门狗计数值为0前要喂狗 否则会复位
		if( loadnum<500)
		{
			//wdog_feed(50000000);	//喂狗-不喂狗会进行复位
		}
	}	
}



