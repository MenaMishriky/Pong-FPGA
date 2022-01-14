`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/12/2022 09:23:08 PM
// Design Name: 
// Module Name: Physics_Pre_Sim
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


module Physics_Pre_Sim();
    //inputs
    reg pad0_dir_t, new_data_t, clk_25MHz_t, reset_t, vert_blank_t;
    reg [7:0] paddle0_speed_t;
    //outputs
    wire [9:0] paddle0_pos_t;
    wire [9:0] paddle1_pos_t;
    wire [9:0] ball_pos_x_t;
    wire [9:0] ball_pos_y_t;
    integer counter;
    
    //indicate that ball or paddles are out of the screen
    wire Flag_ball_y, Flag_ball_x, Flag_paddle0, Flag_paddle1;
    assign Flag_ball_y = (ball_pos_y_t > 479- 'd8);
    assign Flag_ball_x = (ball_pos_x_t > 639- 'd8);
    assign Flag_paddle0 = (paddle0_pos_t > 479- 'd40);
    assign Flag_paddle1 = (paddle1_pos_t > 479- 'd40);
    
    Physics_top DUT (.paddle0_speed(paddle0_speed_t),
                .paddle0_dir(pad0_dir_t),
                .new_data(new_data_t),
                .clk_25MHz(clk_25MHz_t),
                .reset(reset_t),
                .vert_blank(vert_blank_t),
                .paddle0_pos(paddle0_pos_t),
                .paddle1_pos(paddle1_pos_t),
                .ball_pos_x(ball_pos_x_t),
                .ball_pos_y(ball_pos_y_t)
    );
    
    initial begin
        reset_t = 1'b1;
        new_data_t = 1'b0;
        vert_blank_t = 1'b0;
        counter = 0;  
        pad0_dir_t = $urandom_range(0,1);
        paddle0_speed_t = $urandom_range(0,255);
        clk_25MHz_t = 1'b0;
        #100;
        reset_t = 1'b0;   
        
    end
    
    always #20 clk_25MHz_t = ~clk_25MHz_t;   
 
    always @(posedge clk_25MHz_t) begin
        counter = counter + 1;
        //20KHz PS2 data, but 33 bits so we have new data at 606Hz which is every 1.65 ms. This clock triggers once every 40ns, so we need 41250 counts
        if ((counter % 41250) == 0) begin
            new_data_t = 1'b1;
            pad0_dir_t = $urandom_range(0,1);
            paddle0_speed_t = $urandom_range(0,255);
        end   
        else
            new_data_t = 1'b0; 
        
        //vert_blank at 60Hz so once every 16.67ms. Dividee by 40ns which is the freq of this clock and we get 416750 counts
        if ((counter % 416750) == 0)
            vert_blank_t = 1'b1;
        else
            vert_blank_t = 1'b0;
    end               
    
endmodule
