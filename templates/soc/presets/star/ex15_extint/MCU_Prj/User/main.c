#include <stdio.h>
#include <inttypes.h>
#include "STAR.h"
#include "STAR_gpio.h"
#include "extint.h"


int main(void)
{	
	mcu_bsp();
	printf("STAR EXTINT test...\r\n");
	while(1)
	{
		;
	}
}
