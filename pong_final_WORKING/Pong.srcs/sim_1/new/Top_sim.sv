`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2022 09:41:29 PM
// Design Name: 
// Module Name: Top_sim
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


module Top_sim();

wire [3:0] red_VGA, blue_VGA, green_VGA, enables;
wire [7:0] segs;

reg reset, clk_100MHz;

initial begin
   reset = 0;
   clk_100MHz = 0;
   #10;
   reset = 1'b1;
   #100 reset = 0;
end
always # 10 clk_100MHz = ~clk_100MHz;

   Pong_top DUT( PS2_CLK,
                 PS2_DATA,
                 clk_100MHz,
                 reset,
                 
                 hsync_VGA,
                 vsync_VGA,
                 red_VGA,
                 green_VGA,
                 blue_VGA,
                 segs,
                 enables
                 );
endmodule
