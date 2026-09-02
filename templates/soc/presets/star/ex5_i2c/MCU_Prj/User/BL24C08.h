#ifndef __BL24C08_H
#define __BL24C08_H	 

#include "STAR.h"
								  
void EEPROM_ReadWrite_test(void);
void I2C_ByteWrite_nBytes (uint8_t slave_addr,uint16_t word_addr,uint8_t* Buffer,uint8_t Num);
void I2C_EEPROM_RandomRead(uint8_t slave_addr,uint16_t word_addr,uint8_t* Buffer,uint16_t rx_data_num);

#endif
