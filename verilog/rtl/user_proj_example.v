// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */
`include "../../../verilog/rtl/counter.v"

module user_proj_example #(
	parameter BITS = 16
)(
`ifdef USE_POWER_PINS
	inout vccd1,	// User area 1 1.8V supply
	inout vssd1,	// User area 1 digital ground
`endif

	// // Wishbone Slave ports (WB MI A)
	input wb_clk_i,
	input wb_rst_i,

	// Logic Analyzer Signals
	input  [127:0] la_data_in,
	output reg [127:0] la_data_out,
	input  [127:0] la_oenb
);
	wire clk;
	wire rst;
	reg master_enable, master_load, master_write_ena, enable_proc, enable_write;
	wire slv_done, updateRegs;
	wire [BITS-1:0] la_write;
	parameter DELAY = 2000;

	reg [162:0] rega, regb, regc, regd, rege, regf, regh;
	// FSM Definition
	reg [1:0]current_state, next_state;
	parameter idle=2'b00, write_mode=2'b01, proc=2'b11, read_mode=2'b10;
	reg master_start, read_done, master_read;
	reg cpuStatus;
	// Assuming LA probes [63:32] are for controlling the count register  
	assign la_write = ~la_oenb[63:64-BITS];
	// Assumming cpuStatus 
	// assign cpuStatus = (la_data_in[15:0] == 16'hFFFF |) ? 1'b1 : (la_data_in[125] | la_data_in[124] | la_data_in[123] | la_data_in[122]);
	// Assuming LA probes [65:64] are for controlling the count clk & reset  
	assign clk = wb_clk_i;
	assign rst = wb_rst_i;
	assign slv_done = (current_state == 2'b11) ? 1'b1 : 1'b0;
	counter delay (
		.clk(clk),
		.reset(rst),
		.enb(master_write_ena),
		.done(updateRegs)
	);
	
	always @(posedge clk or rst) begin
		if (rst) 
			current_state <= idle;
		else
			current_state <= next_state;
	end

	always @(la_data_in or read_done or updateRegs) begin
		case (current_state)
			idle: begin
				if (enable_write == 1'b1) begin
					next_state <= write_mode;
				end else begin 
					next_state <= idle;
				end
			end

			write_mode: begin
				if (enable_proc == 1'b1) begin
					next_state <= proc;
				end else begin 
					next_state <= write_mode;
				end
			end

			proc: begin
				if (updateRegs == 1'b1) begin
                	next_state <= read_mode;
				end else begin 
					next_state <= proc;
				end
			end

			read_mode: begin
				if (read_done == 1'b1) begin
					next_state <= idle;
				end else begin
					next_state <= read_mode;
				end
			end

			default:
			next_state <= idle;
		endcase
	end

	always @(*) begin
		case (current_state)
			idle: begin
				master_enable <= 1'b0;
				master_load <= 1'b0;
                master_write_ena <= 1'b0;
				if (la_data_in[15:0] == 16'hFFFF ) 
					cpuStatus = 1'b1;
				else
					cpuStatus = 1'b0;
			end 

			write_mode: begin
				master_enable <= 1'b0;
				master_load <= 1'b1;
                master_write_ena <= 1'b0;
				if (la_data_in[125] | la_data_in[124] | la_data_in[123] | la_data_in[122] == 1'b1) begin
					cpuStatus = 1'b1;
				end else begin
					cpuStatus = 1'b0;
				end
			end

			proc: begin
				master_write_ena <= 1'b1;
				master_enable <= 1'b1;
				master_load <= 1'b0;
			end

			read_mode: begin
				master_write_ena <= 1'b0;

				master_enable <= 1'b0;
				master_load <= 1'b0;
				if (la_data_in[15:0] == 16'hFFFF ) 
					cpuStatus = 1'b1;
				else
					cpuStatus = 1'b0;
                
			end
			default: begin
				master_enable <= 1'b0;
				master_load <= 1'b0;
                master_write_ena <= 1'b0;
				if (la_data_in[15:0] == 16'hFFFF ) 
					cpuStatus = 1'b1;
				else
					cpuStatus = 1'b0;
			end 
		endcase 
	end

	always @(posedge clk or rst) begin
		if (rst) begin
			rega <= 0;
			regb <= 0;
			regc <= 0;
			regd <= 0;
			rege <= 0;
			regf <= 0;
			regh <= 0;
			la_data_out <= {(128){1'b0}};
			read_done <= 1'b0;
		end else begin
			case (current_state)
				idle: begin
					rega <= 0;
					regb <= 0;
					regc <= 0;
					regd <= 0;
					rege <= 0;
					regf <= 0;
					regh <= 0;
					read_done <= 1'b0;
					la_data_out[127:122] <= 6'b010000; 
					/* 
					When process being busy (la_data_in[15:0] == 16'hFFFF), 
					BEC core automatically continues processing the existence data
					*/
					if (la_data_in[15:0] == 16'hFFFF) begin			// Enable Full-load Processing
						enable_write <= 1'h1;
					end else if (la_data_in[31:16] == 16'hAB40) begin
						enable_write <= 1'h1;
					end else 
						enable_write <= 1'h0;
				end 

				write_mode: begin
					if (la_data_in[15:0] == 16'hFFFF) begin			// Enable Full-load Processing
						enable_proc <= 1'h1;
					end else if (la_data_in[31:16] == 16'hAB41) begin
						enable_proc <= 1'h1;
					end else 
						enable_proc <= 1'h0;

					if (la_data_in[95:82] == 14'b00000000000001) begin
						rega[162:82] 	<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0001; 	//0x04
					end else if (la_data_in[95:82] == 14'b00000000000011) begin
						rega[81:0] 		<= la_data_in[81:1];
						la_data_out[125:122] <= 4'b0010;	//0x08
					end else if (la_data_in[95:82] == 14'b00000000000111) begin
						regb[162:82] 	<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0011;	//0x0C
					end else if (la_data_in[95:82] == 14'b00000000001111) begin
						regb[81:0] 		<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0100; 	//0x10
					end else if (la_data_in[95:82] == 14'b00000000011111) begin
						regc[162:82] 	<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0101;	//0x14
					end else if (la_data_in[95:82] == 14'b00000000111111) begin
						regc[81:0] 		<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0110;	//0x18
					end else if (la_data_in[95:82] == 14'b00000001111111) begin
						regd[162:82] 	<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0111;	//0x1C
					end else if (la_data_in[95:82] == 14'b00000011111111) begin
						regd[81:0] 		<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b1000;	//0x20
					end else if (la_data_in[95:82] == 14'b00000111111111) begin
						rege[162:82] 	<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1001;	//0x24
					end else if (la_data_in[95:82] == 14'b00001111111111) begin
						rege[81:0] 		<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b1010;	//0x28
					end else if (la_data_in[95:82] == 14'b00011111111111) begin
						regf[162:82] 	<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1011;	//0x2C
					end else if (la_data_in[95:82] == 14'b00111111111111) begin
						regf[81:0] 		<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b1100; 	//0x30
					end else if (la_data_in[95:82] == 14'b01111111111111) begin
						regh[162:82] 	<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1101;	//0x34
					end else if (la_data_in[95:82] == 14'b11111111111111) begin
						regh[81:0] 		<= la_data_in[80:0];
						la_data_out[127:122] <= 6'b011110;	//0x78
					end
				end
				
				proc: begin
					la_data_out[127:122] <= 6'b100111;
					la_data_out[121:0] <= {(122){1'b0}};
				end

				read_mode: begin
					// if (la_data_in[15:0] == 16'hFFFF) begin
					// 	read_done <= 1'h1;
					// end else 
					if (la_data_in[31:16] == 16'hAB40) begin
						read_done <= 1'h1;
					end else 
						enable_write <= 1'h0;
					case (la_data_in[31:16]) 
						16'h0400: begin
							la_data_out[113:32] 	<= rega[80:0]; 
							la_data_out[127:114]	<= 14'b11001000000000;
						end

						16'h0800: begin
							la_data_out[113:32] 	<= regb[162:81]; 
							la_data_out[127:114]	<= 14'b11001100000000;
						end

						16'h0C00: begin
							la_data_out[113:32] 	<= regb[80:0]; 
							la_data_out[127:114]	<= 14'b11010000000000;
						end
						default: begin
							la_data_out[113:32] 	<= rega[162:81]; 
							la_data_out[127:114]	<= 14'b11000100000000;
						end

					endcase
					
				end
				
				default: begin
					rega <= {{(BITS-1){1'b0}}};
					regb <= {{(BITS-1){1'b0}}};
					la_data_out <= {(128){1'b0}};
					read_done <= 1'b0;
				end
			endcase
		end
	end
endmodule

`default_nettype wire
