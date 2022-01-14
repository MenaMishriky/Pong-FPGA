`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/06/2022 06:15:08 PM
// Design Name: 
// Module Name: Physics_top
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

//This module is responsible for calculating the positions of both the paddles and the ball
//upon a positive edge of new_data, the module updates the position of the paddles and the ball.
//**THINK ABOUT THIS** to avoid CDC between clk_25MHz and the PS2 clk upon which data will be available, we will update the output only at the posedge of clk_25MHz at vertical blanking start
module Physics_top( input wire [7:0] paddle0_speed,
                    input wire paddle0_dir,//1 is up, 0 is down
                    input wire new_data,
                    input wire clk_25MHz,
                    input wire reset,
                    input wire vert_blank,
                    output reg [9:0] paddle0_pos,
                    output reg [9:0] paddle1_pos,//top left corner of the AI controlled paddle 1
                    output reg [9:0] ball_pos_x,
                    output reg [9:0] ball_pos_y);
    //constants for the game                
    parameter BALL_SIZE = 8;
    parameter PADDLE_L = 40;
    parameter PADDLE_W = 10;
    parameter BALL_SPEED = 4;//the same speed for X and Y
    parameter PADDLE1_SPEED = 18; //constant paddle 1 speed per frame
    //convert paddle_speed from 8bit PS2 into a number between 0 to 4 pixels per packet upon receiving new data
   reg [2:0] paddle0_speed_int;
 
   always@ (posedge new_data or posedge reset) begin//this occurs at the posedge of new data
        if (reset)
            paddle0_speed_int <= 'd0;
        else if (paddle0_speed > 'd240)
            paddle0_speed_int <= 'd4;
        else if (paddle0_speed > 'd200)
            paddle0_speed_int <= 'd3;
        else if (paddle0_speed > 'd100)
            paddle0_speed_int <= 'd2;
        else if (paddle0_speed > 'd1)
            paddle0_speed_int <= 'd1;
        else 
            paddle0_speed_int <= 'd0;
   end
   
   always @(posedge reset or negedge clk_25MHz) begin //MAKE THIS NEGEDGE TO RESOLVE USING OLD SPEED AND NEW DIR ISSUE
           if (reset)
                  paddle0_pos <= 'd0;
              else if (new_data) begin//idea for this to be separate is that new_data will be detected at the clk_25MHz cycle where new_data falls to 0, so after speed decoding above
                   paddle0_pos <= paddle0_dir?//update paddle position
                                     ( ( (paddle0_pos) <= paddle0_speed_int )?(0):(paddle0_pos - paddle0_speed_int) )://going up. NOTE I use pos < speed INSTEAD of pos < 0 because of unsigned comparison
                                     ( ((paddle0_pos + paddle0_speed_int)>=('d479 - PADDLE_L))?('d479 - PADDLE_L):(paddle0_pos + paddle0_speed_int) );//going down
              end    
      end
       
   //Ball stuff
   wire coll_twall, coll_bwall, pass_lwall, pass_rwall, coll_pad0, coll_pad1; //flags for ball collision with top wall, bottom wall, left, right, or paddle0 (later add paddle1)
   reg ball_dir_x, ball_dir_y;//1 is up/right, 0 is down/left
   assign coll_twall = ((ball_dir_y)&&((ball_pos_y ) <= BALL_SPEED));// unsigned comparison so using speed instead of 0
   assign coll_bwall = ((!ball_dir_y)&&((ball_pos_y + BALL_SIZE +BALL_SPEED)>= 'd479));
   assign pass_lwall = (!ball_dir_x)&&((ball_pos_x ) <= BALL_SPEED);
   assign pass_rwall = (ball_dir_x)&&((ball_pos_x +BALL_SIZE + BALL_SPEED) >= 639);
   //we are colliding with the pad if 1) we re going left and 2)our x position is within the pad width and 3) either our bottom edge is between the pad's top and bottom or our top edge is between the pad's top and bottom
   assign coll_pad0 = (!ball_dir_x)&&
                      ((ball_pos_x - BALL_SPEED) <= PADDLE_W)&&
                      ( ( ((ball_pos_y +BALL_SIZE) >= paddle0_pos) && ((ball_pos_y + BALL_SIZE) <= (paddle0_pos + PADDLE_L)) )||( ((ball_pos_y) >= paddle0_pos) && ((ball_pos_y) <= (paddle0_pos + PADDLE_L))));//for now, this is a simplified collision model. it could be improved
   assign coll_pad1 = (ball_dir_x)&&
                      ((ball_pos_x + BALL_SIZE + BALL_SPEED) >= ('d639 - PADDLE_W))&&
                      ( ( ((ball_pos_y +BALL_SIZE) >= paddle1_pos) && ((ball_pos_y + BALL_SIZE) <= (paddle1_pos + PADDLE_L)) )||( ((ball_pos_y) >= paddle1_pos) && ((ball_pos_y) <= (paddle1_pos + PADDLE_L))));
  
   //updating ball position and direction                            
   always @(posedge reset or posedge vert_blank) begin
        if(reset) begin
            ball_dir_x <=1'b1;
            ball_dir_y <= 1'b1;
            ball_pos_x <= 'd300;
            ball_pos_y <= 'd100;
            paddle1_pos <= 'd0;
        end
        else begin     
            //calculating ball positions x and y. We need to take into account collisions with top&bottom walls, and for now just paddle0
            //also, if the ball hits left or right edge, ball respawns in the middle
            //for now pretty much all collisions are 90 degrees
            if(coll_twall) begin
                ball_dir_y <= 1'b0;
                ball_pos_y <= ball_pos_y + BALL_SPEED;
                ball_pos_x <= ball_dir_x? ball_pos_x + BALL_SPEED: ball_pos_x - BALL_SPEED;
            end
            else if (coll_bwall) begin
                ball_dir_y <= 1'b1;
                ball_pos_y <= ball_pos_y - BALL_SPEED;
                ball_pos_x <= ball_dir_x? ball_pos_x + BALL_SPEED: ball_pos_x - BALL_SPEED;
            end
            else if (pass_lwall) begin//reset the ball
                ball_dir_x <=1'b0;
                ball_dir_y <= 1'b1;
                ball_pos_x <= 'd300;
                ball_pos_y <= 'd100;
            end
            else if (pass_rwall) begin//reset the ball
                ball_dir_x <=1'b1;
                ball_dir_y <= 1'b1;
                ball_pos_x <= 'd300;
                ball_pos_y <= 'd100;
            end
            else if (coll_pad0) begin //for now we do this just for paddle 0. This is a simple collision moddle
                ball_dir_x <= 1'b1;
                ball_pos_x <= ball_pos_x + BALL_SPEED;
                ball_pos_y <= ball_dir_y? ball_pos_y - BALL_SPEED: ball_pos_y + BALL_SPEED;
            end
            else if (coll_pad1) begin
                ball_dir_x <= 1'b0;
                ball_pos_x <= ball_pos_x - BALL_SPEED;
                ball_pos_y <= ball_dir_y? ball_pos_y - BALL_SPEED: ball_pos_y + BALL_SPEED;
            end
            else begin//no collisions, continue as normal
                ball_pos_x <= ball_dir_x? ball_pos_x + BALL_SPEED: ball_pos_x - BALL_SPEED;
                ball_pos_y <= ball_dir_y? ball_pos_y - BALL_SPEED: ball_pos_y + BALL_SPEED;
            end//ball movement
            
            //paddle1 AI movement
            if (reset) 
                paddle1_pos <= 0;
            else begin
                if ((paddle1_pos + (PADDLE_L/'d2)) > (ball_pos_y + (BALL_SIZE/'d2))) begin //is the center of the paddle below the center of the ball? go up
                    paddle1_pos <= ((paddle1_pos) < PADDLE1_SPEED)? 0: paddle1_pos - PADDLE1_SPEED; //I compare to PADDLE1_SPEED instead of 0 due to unsigned comparison
                end
                else if( (paddle1_pos + (PADDLE_L/'d2)) < (ball_pos_y + (BALL_SIZE/'d2))) begin //is center of paddle above center of ball? go down
                    paddle1_pos <= ((paddle1_pos + PADDLE1_SPEED) > ('d479 - PADDLE_L))? ('d479 - PADDLE_L): paddle1_pos + PADDLE1_SPEED;
                end 
            end//paddle1 AI movement
        end//if not reset
   end//always
endmodule
