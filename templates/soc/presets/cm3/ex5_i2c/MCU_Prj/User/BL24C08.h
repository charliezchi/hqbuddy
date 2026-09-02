#ifndef __BL24C08_H
#define __BL24C08_H	 
#include "CM3DS_MPS2.h"

/*CM3 I2C OWN_ADDR*/
#define CM3_I2C_OWN_ADDR 	0x000B

/*I2C时钟频率(Hz)*/
#define I2C_CLK_FREQ	 400000//200000   400000  100000

void I2C_ByteWrite_nBytes (uint8_t slave_addr,uint8_t addr,uint8_t* Buffer,uint8_t Num);								  
void I2C_EEPROM_RandomRead(uint8_t slave_addr,uint8_t word_addr,uint8_t* Buffer,uint8_t rx_data_num);
#endif
