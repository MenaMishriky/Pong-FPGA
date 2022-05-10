`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2022 11:55:38 AM
// Design Name: 
// Module Name: Pong_top
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


module Pong_top( inout PS2_CLK,
                 inout PS2_DATA,
                 input clk_100MHz,
                 input reset,
                 output hsync_VGA,
                 output vsync_VGA,
                 output [3:0] red_VGA,
                 output [3:0] green_VGA,
                 output [3:0] blue_VGA,
                 output [7:0] segs,
                 output [3:0] enables,
                 
                 //DFT mouse ctrl fsm
                 output LED_mouseCTL_RESET,
                 output LED_mouseCTL_WAIT_ACK,
                 output LED_mouseCTL_IDLE_REPORTING,
                 output LED_mouseCTL_INVALID_DATA,
                  //DFT low level interd 
                 output reg LED_ID_received, 
                 output reg LED_data_available_triggered,
                 output reg LED_TX_ERROR_triggered,
                 output reg LED_RX_ERROR_triggered,
                 output reg LED_WORD3_triggered
                 );
   
   //create the 25MHz clock
   wire clk_25MHz;
   clk_wiz_0 clk_gen(.clk_out1(clk_25MHz),
                     .reset(reset),
                     .locked(),
                     .clk_in1(clk_100MHz)
                     ); 
   
   wire clk_300Hz;
   reg [16:0]counter;
   always @(posedge clk_100MHz or posedge reset) begin
      if (reset)
         counter = 0;
      else
         counter = counter + 1;
   end
   assign clk_300Hz = counter[16];
   
   wire [10:0] rx_data_mouse;//rx data from mouse's low level interface
   wire rx_data_available_mouse_low_lvl;// new data available at output of mouse lo level interface
   wire mouse_interf_busy, mouse_interf_error; //low level interface status bits
   wire wr_mouse;//write to the mouse enable
   wire [10:0]F4_command_int;
   wire velocity_available;//new speed and direction data from mouse_ctrl_fsm available flag
   wire y_dir_int, y_max_speed_int;
   wire [7:0] y_speed_int;
   PS2_interf_low_lvl mouse_interf(PS2_CLK,
                                   PS2_DATA,
                                   clk_25MHz,
                                   reset,
                                   F4_command_int,
                                   wr_mouse,
                                   rx_data_mouse,
                                   rx_data_available_mouse_low_lvl,
                                   mouse_interf_busy,
                                   mouse_interf_error);
   mouse_ctrl_fsm mouse_ctl( clk_25MHz,
                   reset,
                   rx_data_mouse,
                   rx_data_available_mouse_low_lvl,
                   mouse_interf_busy,
                   mouse_interf_error,
                   
                   y_dir_int,
                   y_max_speed_int,
                   y_speed_int,
                   velocity_available,
                   F4_command_int,
                   wr_mouse);
    
   wire vert_blank;
   wire[9:0] paddle0_pos;  
   wire[9:0] paddle1_pos;
   wire[9:0] ball_pos_x;
   wire[9:0] ball_pos_y;   
   wire scoreA, scoreB;           
   Physics_top physics (y_max_speed_int? 8'b11111111: y_speed_int,
                        ~y_dir_int,//while the not gate inverts the pad motion, without it it lags like hell
                        velocity_available,
                        clk_25MHz,
                        reset,
                        vert_blank,
                        
                        paddle0_pos,
                        paddle1_pos,//top left corner of the AI controlled paddle 1
                        ball_pos_x,
                        ball_pos_y,
                        scoreA,
                        scoreB
                        );
   
   VGA_driver_top vga (paddle0_pos,
                       paddle1_pos,
                       ball_pos_x,
                       ball_pos_y,
                       clk_100MHz,
                       reset,
                       
                       hsync_VGA,
                       vsync_VGA,
                       red_VGA,
                       green_VGA,
                       blue_VGA,
                       vert_blank
                      );
   
   scorer s1(clk_300Hz,
             reset, 
             scoreA, 
             scoreB, 
             segs,
             enables
           );

//DFT
   always @(posedge clk_100MHz) begin
      if(reset) begin
         LED_data_available_triggered = 0;
         LED_TX_ERROR_triggered = 0;
         LED_RX_ERROR_triggered = 0;
         LED_ID_received = 0;
         LED_WORD3_triggered = 1'b0; 
      end
      else begin
         if (rx_data_available_mouse_low_lvl)
            LED_data_available_triggered = 1'b1;         
         if (mouse_interf.state[mouse_interf.TX_ERROR])
            LED_TX_ERROR_triggered = 1'b1;
         if (mouse_interf.state[mouse_interf.RX_ERROR])
            LED_RX_ERROR_triggered = 1'b1; 
         if (rx_data_mouse == 11'b11000000000)
            LED_ID_received  = 1'b1;  
         if (mouse_ctl.state == mouse_ctl.WORD3)
            LED_WORD3_triggered = 1'b1;        
      end
   end   
   assign LED_mouseCTL_RESET = mouse_ctl.state == mouse_ctl.IDLE_RESET ;
   assign LED_mouseCTL_WAIT_ACK = mouse_ctl.state == mouse_ctl.WAIT_ACK ;
   assign LED_mouseCTL_IDLE_REPORTING = mouse_ctl.state == mouse_ctl.IDLE_REPORTING ;
   assign LED_mouseCTL_INVALID_DATA = mouse_ctl.state == mouse_ctl.INVALID_DATA ;
              
endmodule
