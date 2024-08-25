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
	reg master_enable, master_load, master_write_ena;
	wire slv_done, updateRegs;
	wire [BITS-1:0] la_write;
	parameter DELAY = 2000;

	reg [162:0] rega, regb, regc, regd, rege, regf, regh;
	// FSM Definition
	reg [1:0]current_state, next_state;
	parameter idle=2'b00, write_mode=2'b01, proc=2'b11, read_mode=2'b10;
	reg master_start, read_done, master_read;

	// Assuming LA probes [63:32] are for controlling the count register  
	assign la_write = ~la_oenb[63:64-BITS];

	// Assuming LA probes [65:64] are for controlling the count clk & reset  
	assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
	assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

	// counter #(
	// 	.BITS(BITS),
    //     .DELAY(DELAY)
    // ) delay (
	// 	.clk(clk),
	// 	.reset(rst),
	// 	.enable(master_write_ena),
	// 	.done(updateRegs)
	// );
	
	always @(posedge clk or rst) begin
		if (rst) 
			current_state <= idle;
		else
			current_state <= next_state;
	end

	always @(la_data_in or updateRegs or read_done) begin
		case (current_state)
			idle: begin
				if (la_data_in[31:16] == 16'hAB40) begin
					next_state <= write_mode;
				end else begin 
					next_state <= idle;
				end
			end

			write_mode: begin
				if (la_data_in[63:48] == 16'hAB80) begin
					next_state <= proc;
				end else begin 
					next_state <= write_mode;
				end
			end

			proc: begin
				// if (slv_done) begin
                next_state <= read_mode;
				// end else begin 
					// next_state <= proc;
				// end
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
                master_write_ena <= 1'b0;
			end 

			write_mode: begin
				master_enable <= 1'b0;
				master_load <= 1'b1;
                master_write_ena <= 1'b0;
			end

			proc: begin
				master_enable <= 1'b1;
				master_load <= 1'b0;
                master_write_ena <= 1'b0;
			end

			read_mode: begin
				master_enable <= 1'b0;
				master_load <= 1'b0;
                master_write_ena <= ~updateRegs;
                // if (updateRegs) begin
                //     master_write_ena <= 1'b0;
                // end begin
                //     master_write_ena <= 1'b1;
                // end
                
			end
			default: begin
				master_enable <= 1'b0;
				master_load <= 1'b0;
                master_write_ena <= 1'b0;
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
            count <= 1'b0;
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
				end 

				write_mode: begin
					if (la_data_in[95:82] == 14'h0001) begin
						rega[162:82] 	<= la_data_in[81:0];
					end else if (la_data_in[95:82] == 14'h0002) begin
						rega[81:0] 		<= la_data_in[80:0];
					end else if (la_data_in[95:82] == 14'h0003) begin
						regb[162:82] 	<= la_data_in[81:0];
					end else if (la_data_in[95:82] == 14'h0004) begin
						regb[81:0] 		<= la_data_in[80:0];
					end else if (la_data_in[95:82] == 14'h0005) begin
						regc[162:82] 	<= la_data_in[81:0];
					end else if (la_data_in[95:82] == 14'h0006) begin
						regc[81:0] 		<= la_data_in[80:0];
					end else if (la_data_in[95:82] == 14'h0007) begin
						regd[162:82] 	<= la_data_in[81:0];
					end else if (la_data_in[95:82] == 14'h0008) begin
						regd[81:0] 		<= la_data_in[80:0];
					end else if (la_data_in[95:82] == 14'h0009) begin
						rege[162:82] 	<= la_data_in[81:0];
					end else if (la_data_in[95:82] == 14'h000A) begin
						rege[81:0] 		<= la_data_in[80:0];
					end else if (la_data_in[95:82] == 14'h000B) begin
						regf[162:82] 	<= la_data_in[81:0];
					end else if (la_data_in[95:82] == 14'h000C) begin
						regf[81:0] 		<= la_data_in[80:0];
					end else if (la_data_in[95:82] == 14'h000D) begin
						regh[162:82] 	<= la_data_in[81:0];
					end else if (la_data_in[95:82] == 14'h000E) begin
						regh[81:0] 		<= la_data_in[80:0];
					end
				end
				
				proc: begin
					la_data_out <= {(128){1'b0}};
				end

				read_mode: begin
                    if (updateRegs) begin
                        if (count == 16'h0001) begin
                            la_data_out <= {{(128-BITS){1'b1}}, rega};
                        end else if (count == 16'h0002)  begin
                            la_data_out <= {{(128-BITS){1'b1}}, regb};
                        end
                            
                        if (count < 3) begin
                            count <= count + 1'b1;
                            read_done <= 1'b0;
                        end else begin
                            count <= 1'b0;
                            read_done <= 1'b1;
                        end
                    end
					
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
