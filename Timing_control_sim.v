`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2021 01:45:15 PM
// Design Name: 
// Module Name: Timing_control_sim
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


module Timing_control_sim(output hsync_t, //negative polarity
                       output vsync_t, //negative polarity
                       output de_t, //1 = can draw, 0= cant draw
                       output wire [9:0] sx_t,//position of pointer (x)
                       output wire [9:0] sy_t);
    
    reg clk_pxl_t;
    reg reset_n_t;
    
    Timings_control controller (.clk_pxl(clk_pxl_t),
                                .reset_n(reset_n_t), 
                                .hsync(hsync_t), 
                                .vsync(vsync_t), 
                                .de(de_t),
                                .sx(sx_t), 
                                .sy(sy_t)
                                );
                                
    initial begin
        reset_n_t = 1;
        clk_pxl_t = 0;
        #10;
        reset_n_t = 0;
        #10;
        reset_n_t = 1;
    end
 
    always #40 clk_pxl_t = ~clk_pxl_t;
 
endmodule
