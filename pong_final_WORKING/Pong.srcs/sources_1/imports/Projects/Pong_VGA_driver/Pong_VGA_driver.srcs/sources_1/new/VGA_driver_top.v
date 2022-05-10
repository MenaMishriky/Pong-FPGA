`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2021 11:30:38 AM
// Design Name: 
// Module Name: VGA_driver_top
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


module VGA_driver_top(input [9:0] paddle0_pos,//FOR NOW THESE ARE const Parameters (testing purposes)
                      input [9:0] paddle1_pos,
                      input [9:0] ball_pos_x,//BUT later these should come from another block *****
                      input [9:0] ball_pos_y,
                      input clk_100MHz,
                      input reset,
                      output hsync_VGA,
                      output vsync_VGA,
                      output [3:0] red_VGA,
                      output [3:0] green_VGA,
                      output [3:0] blue_VGA,
                      output vert_blank        
    );
//generating the 25MHz clock from the 100 MHz clock
 wire clk_pxl;
 reg [1:0] counter;
 always @(posedge clk_100MHz or posedge reset) begin
    if(reset)
        counter <=0;
    else
        counter <= counter + 1;
 end
 
 assign clk_pxl = counter[1];
 wire de_int;
 wire [9:0] sx_int;
 wire [9:0] sy_int;
 
 //FOR NOW THESE ARE INITIALIZED (testing purposes), but later they should come from the other block******
// wire [9:0] paddle0_pos = 'd60;
 //wire [9:0] paddle1_pos = 'd60;
 //wire [9:0] ball_pos_x = 'd200;
 //wire [9:0] ball_pos_y = 'd60;
 
 Timings_control controller( .clk_pxl(clk_pxl),
                             .reset(reset),
                             .hsync(hsync_VGA),
                             .vsync(vsync_VGA),
                             .de(de_int),
                             .sx(sx_int),
                             .sy(sy_int),
                             .vert_blank(vert_blank)
                             );
                                
 RGB_Display drawer (.clk_pxl(clk_pxl),
                     .sx(sx_int),
                     .sy(sy_int),
                     .de(de_int),
                     .reset(reset),
                     .paddle0_pos_y(paddle0_pos),
                     .paddle1_pos_y(paddle1_pos),
                     .ball_pos_x(ball_pos_x),
                     .ball_pos_y(ball_pos_y),
                     .vga_red(red_VGA),
                     .vga_green(green_VGA),
                     .vga_blue(blue_VGA)
                     );

endmodule
