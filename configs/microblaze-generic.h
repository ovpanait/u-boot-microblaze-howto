/*
 * Minimal configuration needed to run u-boot on Microblaze.
 *
 * Tested config:
 * - Memory map:
 *   0x00000000 - 0x0001ffff -> 128 KB BRAM
 *   0x04000000 - 0x07ffffff -> 64  MB DRAM
 *   0x41200000 - 0x4120FFFF -> AXI Interrupt Controller
 *   0x41C00000 - 0x41C0FFFF -> AXI Timer
 *   0x40600000 - 0x4060FFFF -> AXI UARTlite
 *   0x41400000 - 0x41400FFF -> Microblaze Debug Module
 *
 * - Peripherals
 *   AXI Interrupt controller
 *   AXI UARTLite
 *   AXI Timer
 *
 * Not tested yet:
 * - Ethernet support
 * - Flash support
 */

#ifndef __CONFIG_H
#define __CONFIG_H

#include <linux/sizes.h>

#define CONFIG_SYS_USR_EXCEP

/* SPL */
#define CONFIG_SYS_INIT_RAM_ADDR	0x0
/* BRAM size - will be generated */
#define CONFIG_SYS_INIT_RAM_SIZE	0x00020000

# define CONFIG_SPL_STACK_ADDR		(CONFIG_SYS_INIT_RAM_ADDR + \
					 CONFIG_SYS_INIT_RAM_SIZE - \
					 CONFIG_SYS_MALLOC_F_LEN)

#define CONFIG_SPL_STACK_SIZE		0x100

#define CONFIG_SPL_MAX_FOOTPRINT	(CONFIG_SYS_INIT_RAM_SIZE - \
					 CONFIG_SYS_INIT_RAM_ADDR - \
					 CONFIG_SYS_MALLOC_F_LEN - \
					 CONFIG_SPL_STACK_SIZE)

/* U-boot proper */
#define XSTR(x) STR(x)
#define STR(x) #x

#define CONFIG_SYS_UBOOT_BASE    CONFIG_SYS_TEXT_BASE
#define CONFIG_SYS_RESET_ADDRESS CONFIG_SYS_TEXT_BASE

#ifndef XILINX_DCACHE_BYTE_SIZE
#define XILINX_DCACHE_BYTE_SIZE 32768
#endif

#define CONFIG_SYS_INIT_SP_OFFSET (CONFIG_SYS_INIT_RAM_ADDR + \
				   CONFIG_SYS_INIT_RAM_SIZE -  \
                                   CONFIG_SYS_MALLOC_F_LEN)

#endif	/* __CONFIG_H */
