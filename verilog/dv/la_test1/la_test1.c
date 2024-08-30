/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>
#define reg_wout_0 	(*(volatile uint32_t*)0x30000004)
#define reg_wout_1 	(*(volatile uint32_t*)0x30000008)
#define reg_wout_2 	(*(volatile uint32_t*)0x3000000C)
#define reg_wout_3 	(*(volatile uint32_t*)0x30000010)
#define reg_wout_4 	(*(volatile uint32_t*)0x30000014)

#define reg_zout_0 	(*(volatile uint32_t*)0x30000018)
#define reg_zout_1 	(*(volatile uint32_t*)0x3000001C)
#define reg_zout_2 	(*(volatile uint32_t*)0x30000020)
#define reg_zout_3 	(*(volatile uint32_t*)0x30000024)
#define reg_zout_4 	(*(volatile uint32_t*)0x30000028)
// --------------------------------------------------------

/*
	MPRJ Logic Analyzer Test:
		- Observes counter value through LA probes [31:0] 
		- Sets counter initial value through LA probes [63:32]
		- Flags when counter value exceeds 500 through the management SoC gpio
		- Outputs message to the UART when the test concludes successfuly
*/
static uint32_t write_la(uint32_t wStatus, uint32_t data_reg0, uint32_t data_reg1, uint32_t data_reg2) {
  // enable sinc3
	uint32_t becAddres;
	switch (wStatus) {
		case 0x00000001:
			becAddres = 0x00040000;
		case 0x00000003:
			becAddres = 0x000C0000;
		case 0x00000007:
			becAddres = 0x001C0000;
		case 0x0000000F:
			becAddres = 0x003C0000;
		case 0x0000001F:
			becAddres = 0x007C0000;
		case 0x0000003F:
			becAddres = 0x00FC0000;
		case 0x0000007F:
			becAddres = 0x01FC0000;
		case 0x000000FF:
			becAddres = 0x03FC0000;
		case 0x000001FF:
			becAddres = 0x07FC0000;
		case 0x000003FF:
			becAddres = 0x0FFC0000;
		case 0x000007FF:
			becAddres = 0x1FFC0000;
		case 0x00000FFF:
			becAddres = 0x3FFC0000;
		case 0x00001FFF:
			becAddres = 0x7FFC0000;
		case 0x00003FFF:
			becAddres = 0xFFFC0000;
	}

	reg_la2_data = becAddres & data_reg0;
	reg_la1_data = data_reg1;
	reg_la0_data = data_reg2;
	}

void main()
{
	int j;
	uint32_t becStatus, becState;
	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

	// reg_spi_enable = 1;
	// reg_spimaster_cs = 0x00000;

	// reg_spimaster_control = 0x0801;

	// reg_spimaster_control = 0xa002;	// Enable, prescaler = 2,
										// connect to housekeeping SPI

	// Connect the housekeeping SPI to the SPI master
	// so that the CSB line is not left floating.  This allows
	// all of the GPIO pins to be used for user functions.

	// The upper GPIO pins are configured to be output
	// and accessble to the management SoC.
	// Used to flad the start/end of a test 
	// The lower GPIO pins are configured to be output
	// and accessible to the user project.  They show
	// the project count value, although this test is
	// designed to read the project count through the
	// logic analyzer probes.
	// I/O 6 is configured for the UART Tx line

		reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
		reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

		reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_9  = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_8  = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_7  = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_5  = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_4  = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_3  = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_2  = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_1  = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_0  = GPIO_MODE_USER_STD_OUTPUT;

		reg_mprj_io_6  = GPIO_MODE_MGMT_STD_OUTPUT;

	// Set UART clock to 64 kbaud (enable before I/O configuration)
	// reg_uart_clkdiv = 625;
	reg_uart_enable = 1;

	// Now, apply the configuration
	reg_mprj_xfer = 1;
	while (reg_mprj_xfer == 1);

	// Configure LA probes 2, 1, and 0 [95:0] as outputs from the cpu 
	// Configure LA probes 3 [127:96] as inputs to the cpu
	reg_la0_oenb = reg_la0_iena = 0xFFFFFFFF;    // [31:0]
	reg_la1_oenb = reg_la1_iena = 0xFFFFFFFF;    // [63:32]
	reg_la2_oenb = reg_la2_iena = 0xFFFFFFFF;    // [95:64]
	reg_la3_oenb = reg_la3_iena = 0x00000000;    // [127:96]

	// Flag start of the test 
	reg_mprj_datal	=	0xAB400000;
	reg_la0_data 	=	0xAB400000;

	// Set Counter value to zero through LA probes [63:32]
	becStatus = reg_la3_data_in & 0x00003FFF;
	becState = reg_la3_data_in & 0x0000C000;

	write_la("w1");
	// reg_la1_data = 0xA001000B;

	reg_la1_data = 0xAB400000;
	// Configure LA probes from [63:32] as inputs to disable counter write
	reg_la1_oenb = reg_la1_iena = 0x00000000;    

	while (1) {
		if (becState == 0x00004000) {	// Write Process from Processor to BEC core
		
			// Writing w1 register
			write_la(becStatus, w1[0], w1[1], w1[2]);
			write_la(becStatus, w1[3], w1[4], w1[5]);

			// Writing z1 register
			write_la(becStatus, z1[0], z1[1], z1[2]);
			write_la(becStatus, z1[3], z1[4], z1[5]);

			// Writing w2 register
			write_la(becStatus, w2[0], w2[1], w2[2]);
			write_la(becStatus, w2[3], w2[4], w2[5]);

			// Writing z2 register
			write_la(becStatus, z2[0], z2[1], z2[2]);
			write_la(becStatus, z2[3], z2[4], z2[5]);

			// Writing inv_w0 register
			write_la(becStatus, inv_w0[0], inv_w0[1], inv_w0[2]);
			write_la(becStatus, inv_w0[3], inv_w0[4], inv_w0[5]);

			// Writing d register
			write_la(becStatus, d[0], d[1], d[2]);
			write_la(becStatus, d[3], d[4], d[5]);

			// Writing key register
			write_la(becStatus, key[0], key[1], key[2]);
			write_la(becStatus, key[3], key[4], key[5]);
		} else if (becState == 0x00008000) {
			// Configure LA probes 2, 1, and 0 [95:0] as inputs to the cpu 
			// Configure LA probes 3 [127:96] as output from the cpu
			reg_la0_oenb = reg_la0_iena = 0x00000000;  // [31:0]
			reg_la1_oenb = reg_la1_iena = 0x00000000;  // [63:32]
			reg_la2_oenb = reg_la2_iena = 0x00000000;  // [95:64]
			reg_la3_oenb = reg_la3_iena = 0xFFFFFFFF;  // [127:96]
			// Inform processer being processing
			reg_mprj_datal = 0xAB410000;

		} else if (becState == 0x0000C000) {
			reg_mprj_datal = 0xAB420000;
			// Inform processer being read from BEC
			uint32_t cpuAddress, cpuState;
			cpuAddress = reg_la0_data_in & 
		}
		if (reg_la0_data_in == 0xFFFF000C) {
			reg_mprj_datal = 0xAB410000;
		}
		if (reg_la0_data_in == 0xFFFF000B) {
			reg_mprj_datal = 0xAB420000;
			break;
		}
	}
//	print("\n");
//	print("Monitor: Test 1 Passed\n\n");	// Makes simulation very long!
	reg_mprj_datal = 0xAB510000;
}