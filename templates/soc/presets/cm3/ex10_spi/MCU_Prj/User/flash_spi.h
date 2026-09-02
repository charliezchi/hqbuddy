
#ifndef __FLASH_SPI_H
#define __FLASH_SPI_H

#ifdef __cplusplus
 extern "C" {
#endif

#include "CM3DS_MPS2.h"
	 
typedef uint32_t  u32;
typedef uint16_t u16;
typedef uint8_t  u8;
typedef int32_t  s32;
typedef int16_t s16;
typedef int8_t  s8;
	
#define FLASH_ID 0xEF3017
#define Register2 0x35	 
#define Register1 0x05		

#define FLASH_SIZE_2M	(1024*1024*2ul)
#define FLASH_SIZE_4M	(1024*1024*4ul)
#define FLASH_SIZE_8M	(1024*1024*8ul)

#define WB_FLASH_SECTOR_SIZE 	(1024*4) 
#define WB_FLASH_PAGE_SIZE 	(256)
#define WB_FLASH_PAGES_IN_SECTOR	(WB_FLASH_SECTOR_SIZE/WB_FLASH_PAGE_SIZE)

//flash cmd

#define W25Q_WRITE_DIS			0X04	//write disable
#define W25Q_READ_SR0			0X05	//read status reg1
#define W25Q_WRITE_EN			0X06	//write enable
#define W25Q_READ_SR1			0X35	//read status reg2
#define W25Q_WRITE_SR			0X01	//write status reg
#define W25Q_PAGE_PRG			0X02	//page program
#define W25Q_QUADPAGE_PRG		0X32	//QUAD PAGE PROGRAM
#define W25Q_CHIP_ERASE			0X60	//CHIP ERASE
#define W25Q_SECTOR_ERASE		0X20	//SECTOR ERASE
#define W25Q_LIT_BLOCK_ERASE	0X52	//LITTLE BLOCK ERASE 32K
#define W25Q_BIG_BLOCK_ERASE	0XD8	//BIG BLCOK ERASE 64K
#define W25Q_ALL_ERASE			0XC7	//CHIP ERASE
#define W25Q_ER_SUSPEND			0X75	//ERASE/PROGRAM SUSPEND
#define W25Q_ER_RESUME			0X7A	//ERASE/PROGRAM RESUME
#define W25Q_POWERDOWN			0XB9	//POWER DOWN
#define W25Q_READ				0X03	//READ DATA
#define W25Q_FASTREAD			0X0B	//FAST READ DATA
#define W25Q_FASTREAD_DUAL_OP	0X3B	//FAST READ DUAL OUTPUT
#define W25Q_FASTREAD_QUAD_OP	0X6B	//FAST READ QUAD OUTPUT
#define W25Q_FASTREAD_DUAL_IO	0XBB
#define W25Q_FASTREAD_QUAD_IO	0XEB	//fast read quad i/o
#define W25Q_ERASE_SECU_REG		0X44	//ERASE SECURITY REG
#define W25Q_PROG_SECU_REG		0X42	//PROGRAM SECURITY REG
#define W25Q_READ_SECU_REG		0X48	//READ SECURITY REG
#define W25Q_READ_MANU_ID_REG	0X90	//READ MANUFACTURE&DEVICE ID
#define W25Q_READ_ID			0X9F	//READ Identification
#define W25Q_WAKEUP				0XAB	//RELEASE POWERDOWN
#define W25Q_DUMMY				0X00

void SPI_Flash_Test(void);


#ifdef __cplusplus
}
#endif

#endif /* __CM3DS_SPI_H */

