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
	reg master_enable, master_load;
	wire slv_done;
	wire [BITS-1:0] count;
	wire [BITS-1:0] la_write;
	
	reg [BITS-1:0] rega, regb;
	// FSM Definition
	reg [1:0]current_state, next_state;
	parameter idle=2'b00, write_mode=2'b01, proc=2'b11, read_mode=2'b10;
	reg master_start, read_done, master_read;

	// LA
	// assign la_data_out = (slv_done)? {{(128-BITS){1'b1}}, count}: {(128){1'b0}};

	// Assuming LA probes [63:32] are for controlling the count register  
	assign la_write = ~la_oenb[63:64-BITS];

	// Assuming LA probes [65:64] are for controlling the count clk & reset  
	assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
	assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

	counter #(
		.BITS(BITS)
	) counter(
		.clk(clk),
		.reset(rst),
		.load(master_load),
		.enable(master_enable),
		.a(rega),
		.b(regb),
		.count(count),
		.done(slv_done)
	);
	always @(posedge clk or rst) begin
		if (rst) 
			current_state <= idle;
		else
			current_state <= next_state;
	end

	always @(la_data_in or slv_done or read_done) begin
		case (current_state)
			idle: begin
				if (la_data_in[63:48] == 16'hAB00) begin
					next_state <= write_mode;
				end else begin 
					next_state <= idle;
				end
			end

			write_mode: begin
				if (la_data_in[63:48] == 16'hAB40) begin
					next_state <= proc;
				end else begin 
					next_state <= write_mode;
				end
			end

			proc: begin
				if (slv_done) begin
					next_state <= read_mode;
				end else begin 
					next_state <= proc;
				end
			end

			read_mode: begin
				if (read_done) begin
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
			end 

			write_mode: begin
				master_enable <= 1'b0;
				master_load <= 1'b1;
			end

			proc: begin
				master_enable <= 1'b1;
				master_load <= 1'b0;
			end

			read_mode: begin
				master_enable <= 1'b0;
				master_load <= 1'b0;
			end
			default: begin
				master_enable <= 1'b0;
				master_load <= 1'b0;
			end 
		endcase 
		// if (la_data_in[63:48] == 16'hAB00) begin
		// 	master_enable <= 1'b0;
		// 	master_load <= 1'b1;
		// end else if ((la_data_in[63:48] == 16'hAB40)) begin
		// 	master_enable <= 1'b1;
		// 	master_load <= 1'b0;
		// end else begin
		// 	master_enable <= 1'b0;
		// 	master_load <= 1'b0;
		// end
	end

	always @(posedge clk or rst) begin
		if (rst) begin
			rega <= {{(BITS-1){1'b0}}};
			regb <= {{(BITS-1){1'b0}}};
			la_data_out <= {(128){1'b0}};
			read_done <= 1'b0;
		end else begin
			case (current_state)
				idle: begin
					rega <= {{(BITS-1){1'b0}}};
					regb <= {{(BITS-1){1'b0}}};
					read_done <= 1'b0;
				end 

				write_mode: begin
					if (la_data_in[63:48] == 16'hA000) begin
						rega <= la_data_in[47:32];
					end else if (la_data_in[63:48] == 16'hA001) begin
						regb <= la_data_in[47:32];
					end
				end
				
				proc: begin
					la_data_out <= {(128){1'b0}};
				end

				read_mode: begin
					la_data_out <= {{(128-BITS){1'b1}}, count};
					read_done <= 1'b1;
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

module counter #(
	parameter BITS = 16
)(
	input clk,
	input reset,
	input load,
	input enable,
	input [BITS-1:0] a,
	input [BITS-1:0] b,
	output reg [BITS-1:0] count,
	output reg done
);
	reg [1:0]current_state, next_state;
	reg [BITS-1:0] reg_count;
	reg reg_enb_cnt, reg_load, reg_done;
	parameter idle=2'b00, st_load=2'b01, proc=2'b11, st_done=2'b10;

	always @(posedge clk or reset) begin
		if (reset) 
			current_state <= idle;
		else
			current_state <= next_state;
	end

	always @(load or enable or reg_done) begin
		case (current_state)
			idle: begin
				if (load) begin
					next_state <= st_load;
				end else begin 
					next_state <= idle;
				end
			end

			st_load: begin
				if (enable) begin
					next_state <= proc;
				end else begin  
					next_state <= st_load; 
				end
			end

			proc: begin
				if (reg_done) begin
					next_state <= st_done;
				end else begin 
					next_state <= proc;
				end
			end

			st_done: begin
				next_state <= idle;
			end

			default:
			next_state <= idle;
		endcase
	end
	
	always @(*) begin
		case (current_state)
			idle: begin
				reg_load <= 1'b0;
				reg_enb_cnt <= 1'b0;
				done <= 1'b0;
			end

			st_load: begin
				reg_load <= 1'b1;
				reg_enb_cnt <= 1'b0;
				done <= 1'b0;
			end

			proc: begin
				reg_load <= 1'b0;
				reg_enb_cnt <= 1'b1;
				done <= 1'b0;
			end

			st_done: begin
				reg_load <= 1'b0;
				reg_enb_cnt <= 1'b0;
				done <= 1'b1;
			end
		endcase
	end

	always @(posedge clk or reset) begin
		if (reset) begin
			reg_count <= 1'b0;
			reg_done <= 1'b0;
			count <= 1'b0;
		end else begin
			if (reg_enb_cnt) begin
				if (reg_count < 1000) begin
					reg_count <= reg_count + 1'b1;
					reg_done <= 1'b0;
					// count <= 1'b0;
				end else begin
					reg_count <= 1'b0;
					reg_done <= 1'b1;
					count <= reg_count;
				end
			end else if ((reg_load == 1'b1) && (enable == 1'b0)) begin
				reg_count <=  a;
			end
		end
	end

endmodule
`default_nettype wire
