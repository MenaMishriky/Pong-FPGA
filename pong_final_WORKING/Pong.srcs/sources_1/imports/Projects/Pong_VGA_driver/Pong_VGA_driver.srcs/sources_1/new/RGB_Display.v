`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2021 10:01:04 AM
// Design Name: 
// Module Name: RGB_Display
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

//This module just takes the positions of the ball and paddle and controls the RGB lines. no calculations
module RGB_Display(input clk_pxl,
                   input [9:0] sx,
                   input [9:0] sy,
                   input de,
                   input reset,
                   input [9:0] paddle0_pos_y,
                   input [9:0] paddle1_pos_y,
                   input [9:0] ball_pos_x,
                   input [9:0] ball_pos_y,
                   output wire [3:0] vga_red,
                   output wire [3:0] vga_green,
                   output wire [3:0] vga_blue
    );
parameter border_pos = 319;
parameter border_size = 4; 
parameter ball_size = 8;
parameter paddle_size_x = 10;
parameter paddle_size_y = 40;   
wire draw_en;
reg border;
reg border_history;

//border detection (netted border)
always @(posedge clk_pxl or posedge reset) begin
        if (reset) begin
            border <= 0;
            border_history <=0;
        end
        else if (sx == border_pos -1) begin
            border <= ((sy % 4) == 0)? ~border_history : border_history;
            border_history <= ((sy % 4) == 0)? ~border_history : border_history;
        end
        else if (sx == border_pos -1 + border_size) begin
             border <= 0;
        end
end
//we enable drawing only when we are in the border place, ball place, paddle0 place, or paddle 1 place
assign draw_en = (border) 
                 ||((sx >= ball_pos_x)&&(sx< (ball_pos_x + ball_size)) && (sy>= ball_pos_y) &&(sy < (ball_pos_y + ball_size))) 
                 || ( (sy >= paddle0_pos_y) && (sy < (paddle0_pos_y + paddle_size_y)) && (sx < paddle_size_x) )
                 || ( (sy >= paddle1_pos_y) && (sy < (paddle1_pos_y + paddle_size_y)) && (sx > 'd639 - paddle_size_x) && (sx < 'd639) );
 
 //we are drawing in white on black background only
assign vga_red = (draw_en && de)? 4'hf: 0;
assign vga_blue = (draw_en && de)? 4'hf: 0;
assign vga_green = (draw_en && de)? 4'hf: 0;

endmodule
