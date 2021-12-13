`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2021 12:41:21 PM
// Design Name: 
// Module Name: Timings_control
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

//This module generates the hsync, vsync, sx, sy, and de cnotrol signals for the VGA_driver
module Timings_control(input clk_pxl,
                       input reset_n,
                       output hsync, //negative polarity
                       output vsync, //negative polarity
                       output de, //1 = can draw, 0= cant draw
                       output reg [9:0] sx,//position of pointer (x)
                       output reg [9:0] sy);//position of pointer (y)
   parameter H_Active = 640; //active portion (Horizontal)
   parameter V_Active = 480; //active portion (Vertical)
   parameter H_FrontP = 16;
   parameter V_FrontP = 10;
   parameter H_SyncW = 96;
   parameter V_SyncW = 2;
   parameter H_BackP = 48;
   parameter V_BackP = 33;
   
   always @(posedge clk_pxl or negedge reset_n) begin
        if (!reset_n)begin
            sx<= 0;
            sy<= 0;
        end
        else begin//correctly update sx and sy
            sx <= (sx >= 799)? 0: sx +1; 
            sy <= ((sx>= 799) && (sy>= 524))? 0 : (sx>=799)? sy+1 : sy;
        end
   end
   //signal we are in the active portion
   assign de = (sx < H_Active) && (sy < V_Active);
   //hsync and vsync
   assign hsync = ~( (sx >= (H_Active + H_FrontP)) && (sx < (H_Active + H_FrontP + H_SyncW)) );
   assign vsync = ~( (sy >= (V_Active + V_FrontP)) && (sy < (V_Active + V_FrontP + V_SyncW)) );
endmodule
