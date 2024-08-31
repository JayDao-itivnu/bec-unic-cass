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
#include <../../../verilog/dv/la_test1/sm_bec_v3_randomKey_spec.h>


#define reg_wout_0 	(*(volatile uint32_t*)0x30000004)
#define reg_wout_1 	(*(volatile uint32_t*)0x30000008)
#define reg_wout_2 	(*(volatile uint32_t*)0x3000000C)
#define reg_wout_3 	(*(volatile uint32_t*)0x30000010)
#define reg_wout_4 	(*(volatile uint32_t*)0x30000014)
#define reg_wout_5 	(*(volatile uint32_t*)0x30000018)

#define reg_zout_0 	(*(volatile uint32_t*)0x3000001C)
#define reg_zout_1 	(*(volatile uint32_t*)0x30000020)
#define reg_zout_2 	(*(volatile uint32_t*)0x30000024)
#define reg_zout_3 	(*(volatile uint32_t*)0x30000028)
#define reg_zout_4 	(*(volatile uint32_t*)0x3000002C)
#define reg_zout_5 	(*(volatile uint32_t*)0x30000030)

#define reg_cpuStatus (*(volatile uint32_t*)0x30000034)
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
	uint32_t BecStatus 	= reg_la3_data_in & 0x3C000000; //Take 4 bits of becStatus (la3_data_in[29:26])
	reg_mprj_datal = BecStatus;
	switch (BecStatus) {
		// case 0x04000000:
		// 	becAddres = 0x00040000;
		case 0x04000000:				// la3_data_in[29:26] = "0001"
			becAddres = 0x000C0000;
		case 0x08000000:				// la3_data_in[29:26] = "0010"
			becAddres = 0x001C0000;
		case 0x0C000000:				// la3_data_in[29:26] = "0011"
			becAddres = 0x003C0000;
		case 0x10000000:				// la3_data_in[29:26] = "0100"
			becAddres = 0x007C0000;
		case 0x14000000:				// la3_data_in[29:26] = "0101"
			becAddres = 0x00FC0000;
		case 0x18000000:				// la3_data_in[29:26] = "0110"
			becAddres = 0x01FC0000;
		case 0x1C000000:				// la3_data_in[29:26] = "0111"
			becAddres = 0x03FC0000;
		case 0x20000000:				// la3_data_in[29:26] = "1000"
			becAddres = 0x07FC0000;
		case 0x24000000:				// la3_data_in[29:26] = "1001"
			becAddres = 0x0FFC0000;
		case 0x28000000:				// la3_data_in[29:26] = "1010"
			becAddres = 0x1FFC0000;
		case 0x2C000000:				// la3_data_in[29:26] = "1011"
			becAddres = 0x3FFC0000;
		case 0x30000000:				// la3_data_in[29:26] = "1100"
			becAddres = 0x7FFC0000;
		case 0x34000000:				// la3_data_in[29:26] = "1101"
			becAddres = 0xFFFC0000;
		default:
			becAddres = 0x00040000;
	}
	reg_la2_data = 0;
	reg_la0_data = data_reg2;
	reg_la1_data = data_reg1;
	reg_la2_data = becAddres ^ data_reg0;

	}


static uint32_t read_la (uint32_t cpuState, uint32_t becStatus) {
	switch (becStatus) {
		case 0x04000000: {
			reg_wout_0 = reg_la3_data_in & 0x03FFFFFF;
			reg_wout_1 = reg_la2_data_in;
			reg_wout_2 = reg_la1_data_in;
			
			reg_la0_data = 0x04000000;
		}

		case 0x08000000: {
			reg_wout_3 = reg_la3_data_in & 0x03FFFFFF;
			reg_wout_4 = reg_la2_data_in;
			reg_wout_5 = reg_la1_data_in;

			reg_la0_data = 0x08000000;
		}

		case 0x0C00000: {
			reg_zout_0 = reg_la3_data_in & 0x03FFFFFF;
			reg_zout_1 = reg_la2_data_in;
			reg_zout_2 = reg_la1_data_in;

			reg_la0_data = 0x0C000000;
		}

		case 0x1000000: {
			reg_zout_3 = reg_la3_data_in & 0x03FFFFFF;
			reg_zout_4 = reg_la2_data_in;
			reg_zout_5 = reg_la1_data_in;

			reg_la0_data = 0x10000000;
		}
	}
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

	// Configure BEC Status Notifications [127:122]
	becStatus 	= reg_la3_data_in & 0x3C000000;			// Next 4-bits of addresses inside BEC core
	becState 	= reg_la3_data_in & 0xC0000000;			// First 2-bits of FSM status inside BEC core    

	while (1) {
		if (becState == 0x40000000) {	// Write Process from Processor to BEC core (la3[31:30] = "01")
			while (becStatus != 0x38000000) {
			// Writing w1 register
				write_la(reg_la3_data_in, w1[0], w1[1], w1[2]);
				write_la(reg_la3_data_in, w1[3], w1[4], w1[5]);

				// Writing z1 register
				write_la(reg_la3_data_in, z1[0], z1[1], z1[2]);
				write_la(reg_la3_data_in, z1[3], z1[4], z1[5]);

				// Writing w2 register
				write_la(reg_la3_data_in, w2[0], w2[1], w2[2]);
				write_la(reg_la3_data_in, w2[3], w2[4], w2[5]);

				// Writing z2 register
				write_la(reg_la3_data_in, z2[0], z2[1], z2[2]);
				write_la(reg_la3_data_in, z2[3], z2[4], z2[5]);

				// Writing inv_w0 register
				write_la(reg_la3_data_in, inv_w0[0], inv_w0[1], inv_w0[2]);
				write_la(reg_la3_data_in, inv_w0[3], inv_w0[4], inv_w0[5]);

				// Writing d register
				write_la(reg_la3_data_in, d[0], d[1], d[2]);
				write_la(reg_la3_data_in, d[3], d[4], d[5]);

				// Writing key register
				write_la(reg_la3_data_in, key[0], key[1], key[2]);
				write_la(reg_la3_data_in, key[3], key[4], key[5]);
			}
			reg_la0_data 	=	0xAB410000;
		} else if (becState == 0x80000000) {
			// Configure LA probes 2, 1, and 0 [95:0] as inputs to the cpu 
			// Configure LA probes 3 [127:96] as output from the cpu
			reg_la0_oenb = reg_la0_iena = 0xFFFFFFFF;  // [31:0]
			reg_la1_oenb = reg_la1_iena = 0x00000000;  // [63:32]
			reg_la2_oenb = reg_la2_iena = 0x00000000;  // [95:64]
			reg_la3_oenb = reg_la3_iena = 0x00000000;  // [127:96]
			// Inform processer being processing
			reg_mprj_datal = 0xAB410000;

		} else if (becState == 0xC0000000) {
			reg_mprj_datal = 0xAB420000;
			// Inform processer being read from BEC
			while (becState == 0xC0000000) {
				read_la(becState, becStatus);
			}
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