`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2022 12:04:25 PM
// Design Name: 
// Module Name: Synch_2FF
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


module Synch_2FF(input clk,  
                 input ip,
                 output reg op
    );
    
    reg internal;
    always @(posedge clk) begin
       internal <= ip;
       op <= internal;
    end
    
endmodule
