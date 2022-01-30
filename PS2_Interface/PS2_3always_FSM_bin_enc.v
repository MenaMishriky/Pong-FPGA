`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/21/2022 10:30:37 AM
// Design Name: 
// Module Name: PS2_interf_low_lvl
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


module PS2_interf_low_lvl(inout PS2_clk,
                          inout PS2_data,
                          input wire clk_25MHz,
                          input wire reset,
                          input [10:0] tx_data,
                          input wr_en,
                          output reg [10:0] rx_data,
                          output  reg data_available,
                          output  busy,
                          output err);

  parameter IDLE = 'd0;
  parameter RX_CLK_NEGEDGE = 'd1;
  parameter RX_CLK_L = 'd2;
  parameter RX_CLK_H = 'd3;
  parameter RX_PARITY_CHECK = 'd4;
  parameter RX_ERROR = 'd5;
  parameter RX_DATA_READY = 'd6;
  parameter TX_PULL_CLK_L = 'd7;
  parameter TX_PULL_DATA_L = 'd8;
  parameter TX_REL_CLK = 'd9;
  parameter TX_WAIT_FIRST_CLK_H = 'd10;
  parameter TX_CLK_H = 'd11;
  parameter TX_CLK_NEGEDGE = 'd12;
  parameter TX_CLK_L = 'd13;
  parameter TX_REL_DATA = 'd14;
  parameter TX_WAIT_ACK = 'd15;
  parameter TX_ERROR= 'd16;
  parameter TX_ACK_RECEIVED = 'd17;
  reg [4:0] state;
  reg [4:0] next_state;
  
  reg [3:0] bit_counter;
  reg [10:0] data_received;
  reg rx_parity_ok;
  reg [11:0] delay_100micro_counter; // 100us/25MHz = 2500
  reg [8:0] delay_20micro_counter;//20/0.04 = 500
  reg [8:0] cycles_300_counter;
  reg [11:0] delay_200_micro_counter; //if all 1's
  reg PS2_data_out;//buffer for tristate
  reg [10:0] tx_data_int;//internal signal for tx data, assigned at TX_PULL_CLK_L
  reg PS2_clk_out;
  wire write_to_clk, write_to_data;//enables for tristate buffer
  
   //flags
   assign err = (state == RX_ERROR)||(state == TX_ERROR);
   assign busy = (state != IDLE);
   
  assign write_to_clk = (state == TX_PULL_CLK_L)||(state == TX_PULL_DATA_L);
  assign write_to_data = (state == TX_PULL_DATA_L)||(state == TX_REL_CLK)||(state == TX_WAIT_FIRST_CLK_H) ||(state == TX_CLK_H) 
                          ||(state == TX_CLK_NEGEDGE) ||(state == TX_CLK_L);
  //tri state
  assign PS2_clk = write_to_clk? PS2_clk_out:1'bz;
  assign PS2_data = write_to_data? PS2_data_out: 1'bz;
  
 //delay counters, ensure counters ony count in the right state , and they have to reset once they exit their counting state
 always @(posedge PS2_clk or posedge reset) begin
    if (reset) begin
        delay_100micro_counter <= 0;
        delay_20micro_counter <=0;
        cycles_300_counter <=0;
        delay_200_micro_counter <=0;
    end
    else begin
        case (state)
            TX_PULL_CLK_L: begin
                             delay_100micro_counter <= delay_100micro_counter +1; 
                             delay_20micro_counter <=0;
                             cycles_300_counter <=0;
                             delay_200_micro_counter <=0;
                           end
           TX_PULL_DATA_L: begin
                            delay_100micro_counter <= 0; 
                            delay_20micro_counter <= delay_20micro_counter + 1;
                            cycles_300_counter <=0;
                            delay_200_micro_counter <=0;
                          end
          TX_WAIT_FIRST_CLK_H: begin
                              delay_100micro_counter <= 0; 
                              delay_20micro_counter <= 0;
                              cycles_300_counter <= cycles_300_counter + 1;
                              delay_200_micro_counter <=0;
                            end
          TX_WAIT_ACK: begin
                            delay_100micro_counter <= 0; 
                            delay_20micro_counter <= 0;
                            cycles_300_counter <=0;
                            delay_200_micro_counter <=delay_200_micro_counter + 1;
                          end
         default: begin
                    delay_100micro_counter <= 0; 
                    delay_20micro_counter <= 0;
                    cycles_300_counter <=0;
                    delay_200_micro_counter <=0;
                  end
       endcase
    end
 end

  //FSM STANDARD
  always @(posedge reset or posedge clk_25MHz) begin
    if (reset)
        state <= IDLE;
    else
        state <= next_state;
  end
  
  //next state logic DONE (I think)
  always @* begin
    if (reset) begin
        next_state = IDLE;
        //rx_data <= 11'b10101010101;
        //data_available <= 1'b0;
    end
    else begin
        next_state = 5'bxxxxx;//default for debug
        case (state)
            IDLE: begin
                    //next state logic
                    if (wr_en)
                        next_state = TX_PULL_CLK_L;
                    else if (!PS2_clk)
                        next_state = RX_CLK_NEGEDGE;
                    else
                        next_state = IDLE;
                    
                    //data_available <= 1'b0; //reset flag
                  end
            RX_CLK_NEGEDGE: begin
                              //next state logic
                              next_state = RX_CLK_L;
                              
                            end
            RX_CLK_L: begin
                        //next state logic
                        if (PS2_clk)
                            next_state = RX_CLK_H;
                        else
                            next_state = RX_CLK_L;
                            
                      end
            RX_CLK_H: begin
                        //next state logic
                        if (bit_counter >= 4'b1011)
                            next_state = RX_PARITY_CHECK;
                        else if(!PS2_clk)
                            next_state = RX_CLK_NEGEDGE;
                        else
                            next_state = RX_CLK_H;
                        
                      end
            RX_PARITY_CHECK: begin
                               //next state logic
                               if (rx_parity_ok)
                                 next_state = RX_DATA_READY;
                               else
                                 next_state = RX_ERROR;
                                 
                             end
            RX_ERROR: begin
                        //next state logic
                        next_state = IDLE;
                        
                      end
            RX_DATA_READY: begin
                             //next state logic
                             next_state = IDLE;
                             
                             //rx_data <= data_received;
                             //data_available <= 1'b1;
                           end
            TX_PULL_CLK_L: begin
                            //next state logic
                            if (delay_100micro_counter >= 'd2500)
                                next_state = TX_PULL_DATA_L;
                            else
                                next_state = TX_PULL_CLK_L;
                             
                            //tx_data_int <= tx_data;   
                            //PS2_clk_out <= 1'b0;
                           end
            TX_PULL_DATA_L: begin
                              //next state logic
                              if(delay_20micro_counter >= 'd500)
                                next_state = TX_REL_CLK;
                              else
                                next_state = TX_PULL_DATA_L;
                              //PS2_data_out <= 1'b0;
                              //PS2_clk_out <= 1'b0;
                            end
            TX_REL_CLK: begin
                          //next state logic
                          next_state = TX_WAIT_FIRST_CLK_H;
                          
                         // PS2_clk_out <= 1'b1;
                          //PS2_data_out <=1 'b0;
                        end
            TX_WAIT_FIRST_CLK_H: begin
                                   //next state logic
                                   if(cycles_300_counter >= 'd300)
                                     next_state = TX_CLK_H;
                                   else
                                     next_state = TX_WAIT_FIRST_CLK_H;
                                     
                                   //PS2_data_out <= 1'b0;  
                                 end
            TX_CLK_H: begin
                        //next state logic
                        if (PS2_clk == 1'b0)
                            next_state  = TX_CLK_NEGEDGE;
                        else 
                            next_state = TX_CLK_H;
                            
                        //PS2_data_out <= 1'b0;
                      end
            TX_CLK_NEGEDGE: begin 
                                //next state logic
                                next_state = TX_CLK_L;
                            end
            TX_CLK_L: begin
                            //next state logic
                            if(!PS2_clk)    
                                next_state = TX_CLK_L;
                            else if (bit_counter < 11) 
                                next_state = TX_CLK_H;
                            else
                                next_state = TX_REL_DATA;
                            
                            //PS2_data_out <= PS2_data_out;
                                
                      end
            TX_REL_DATA: begin
                            //next state logic
                            next_state = TX_WAIT_ACK;
                            
                            //PS2_data_out <= 1'b1;
                         end
            TX_WAIT_ACK: begin
                            //next state logic
                            if (!PS2_data)
                                next_state = TX_ACK_RECEIVED;
                            else if (&delay_200_micro_counter)
                                next_state = TX_ERROR;
                            else
                                next_state = TX_WAIT_ACK;   
                         end
            TX_ERROR: begin
                        //next state logic
                        next_state = TX_PULL_CLK_L;
                            
                      end 
            TX_ACK_RECEIVED: begin
                                //next state logic
                                next_state = IDLE;
                                
                             end
            default: begin
                        //next state logic
                        next_state = IDLE;
                     end
          endcase
    end
  end
  
  //output logic 
  always @(posedge clk_25MHz or posedge reset) begin
        if(reset) begin//everything is 0 or garbage
          tx_data_int <= 0;
          PS2_data_out<= 1'b1;//eliminated at reset or idle by tristate anyway  
          PS2_clk_out <= 1'b1;
          data_available <= 1'b0;
          rx_data <= 11'b10101010101;
          data_received <= 11'b10101010101;
          bit_counter <= 0;
          rx_parity_ok <= 1'b1;
        end
        else begin
           //default values
            tx_data_int <= 0;
            PS2_data_out<= 1'b1;//eliminated at reset or idle by tristate anyway  
            PS2_clk_out <= 1'b1;
            data_available <= 1'b0;
            rx_data <= 11'b10101010101;
            data_received <= 11'b10101010101;
            bit_counter <= 0; 
            rx_parity_ok <= 1'b1;
           case (next_state) //note that assignments here replace (not just overwrite) default assignment
              IDLE: begin
                    //no change needed    
                    end
              RX_CLK_NEGEDGE: begin
                              bit_counter <= bit_counter + 1;//will be reset in different state. NOTE THAT THIS SUPERCEDES THE DEFAULT ASSIGNMENTS
                              //shifting data in, coming from the left and doing right shift
                              data_received[10] <= PS2_data;
                              data_received[9:0] <= data_received[10:1];  
                              end
              RX_CLK_L: begin
                          //do not reset these
                          data_received <= data_received;
                          bit_counter <= bit_counter;
                              
                        end
              RX_CLK_H: begin
                          //do not reset these
                            data_received <= data_received;
                            bit_counter <= bit_counter;
                          
                        end
              RX_PARITY_CHECK: begin
                                //do not reset these
                                data_received <= data_received;
                                bit_counter <= bit_counter;       
                                rx_parity_ok <= ((data_received[1] + data_received[2] + data_received[3] + data_received[4] + data_received[5]
                                                 + data_received[6] + data_received[7] + data_received[8] + data_received[9]) % 2);  
                               end
              RX_ERROR: begin
                            //do not reset these
                          data_received <= data_received;
                          bit_counter <= bit_counter;  
                          //do not pass data since its erroneous
                          
                        end
              RX_DATA_READY: begin                              
                               //do not reset these
                              data_received <= data_received;
                              bit_counter <= bit_counter;  
                              rx_data <= data_received;
                              data_available <= 1'b1;
                              
                             end
              TX_PULL_CLK_L: begin
                              tx_data_int <= tx_data;   
                              PS2_clk_out <= 1'b0;
                             end
              TX_PULL_DATA_L: begin
                                tx_data_int <= tx_data_int;
                                PS2_data_out <= 1'b0;
                                PS2_clk_out <= 1'b0;
                              end
              TX_REL_CLK: begin
                           tx_data_int <= tx_data_int;
                           PS2_data_out <= 1'b0;
                           PS2_clk_out <= 1'b1;
                          end
              TX_WAIT_FIRST_CLK_H: begin
                                     PS2_clk_out <= 1'b1;//probaby not needed but just to be safe
                                     PS2_data_out <= 1'b0;  
                                     tx_data_int <= tx_data_int;
                                     bit_counter <= 'd1;//when the first high edge comes, mouse just read our start bit
                                   end
              TX_CLK_H: begin
                           PS2_clk_out <= PS2_clk_out;//probaby not needed but just to be safe
                           PS2_data_out <= PS2_data_out;  
                           tx_data_int <= tx_data_int;
                           bit_counter <=bit_counter;
                        end
              TX_CLK_NEGEDGE: begin //this is where we write
                              //no reason to worry about clock now
                              //shift to the right, and data leaves from the right
                              PS2_data_out <= tx_data_int[0];    
                              tx_data_int[9:0] <= tx_data_int[10:1];
                              bit_counter <= bit_counter + 1;
                              end
              TX_CLK_L: begin
                             PS2_clk_out <= PS2_clk_out;//probaby not needed but just to be safe
                             PS2_data_out <= PS2_data_out;  
                             tx_data_int <= tx_data_int;
                             bit_counter <=bit_counter;
                                
                        end
              TX_REL_DATA: begin
                             PS2_clk_out <= PS2_clk_out;//probaby not needed but just to be safe
                             PS2_data_out <= 1'b1;//probaby not needed but just to be safe
                             tx_data_int <= tx_data_int;
                             bit_counter <=bit_counter;
                           end
              TX_WAIT_ACK: begin
                                //here we shouldnt really do anything, so I hold on to the reg values
                               PS2_clk_out <= PS2_clk_out;//probaby not needed but just to be safe
                               PS2_data_out <= 1'b1;//probaby not needed but just to be safe
                               tx_data_int <= tx_data_int;
                               bit_counter <=bit_counter;
                           end
              TX_ERROR: begin
                           bit_counter <= 1'b0;//reset to send
                           tx_data_int <= tx_data;  //to resend data
                           
                        end 
              TX_ACK_RECEIVED: begin
                                  //dont need to do anything
                                  
                               end
             //defaults already set before the case statement
            endcase
    end
  end
endmodule
