`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2022 02:51:39 PM
// Design Name: 
// Module Name: big_ps2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module big_ps2(output wire y_dir,
               output wire [7:0] y_speed,
               output wire y_max_speed,
               output new_out,
               output wire [10:0] F4_command,
               output write,
               inout PS2_clk,
               inout PS2_data,
               input wire clk_25MHz,
               input wire reset,
               input [10:0] tx_data
               );   
wire [10:0] rx_data_int;
wire data_flag_int, busy_int, err_int;                

    PS2_interf_low_lvl ps2 (.PS2_clk(PS2_clk),
                            .PS2_data(PS2_data),
                            .clk_25MHz(clk_25MHz),
                            .reset(reset),
                            .tx_data(tx_data),
                            .rx_data(rx_data_int),
                            .data_available(data_flag_int),
                            .busy(busy_int),
                            .err(err_int),
                            .wr_en(write)
                            );
                            
    mouse_ctrl_fsm ctrl (.clk_25MHz(clk_25MHz),
                         .reset(reset),
                         .rx_data(rx_data_int),
                         .data_flag(data_flag_int),
                         .busy(busy_int),
                         .err(err_int),
                         .y_dir(y_dir),
                         .y_max_speed(y_max_speed),
                         .y_speed(y_speed),
                         .new_out(new_out),
                         .F4_command(F4_command),
                         .write(write)
                         );

endmodule
