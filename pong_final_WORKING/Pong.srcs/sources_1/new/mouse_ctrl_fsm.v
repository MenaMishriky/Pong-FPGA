module mouse_ctrl_fsm ( input wire clk_25MHz,
                    input wire reset,
                    input [10:0] rx_data,
                    input wire data_flag,
                    input wire busy,
                    input wire err,
                    output /*reg*/ y_dir,
                    output /*reg */y_max_speed,
                    output /*reg*/ [7:0] y_speed,
                    output new_out,
                    output reg [10:0] F4_command,
                    output write);
    // Definition for constant states
    parameter IDLE_RESET = 'd0;
    parameter BUSY_CHECK = 'd1;
    parameter WRITE_F4 = 'd2;
    parameter WAIT_ACK = 'd3;
    parameter IDLE_REPORTING = 'd4;
    parameter WORD1 = 'd5;
    parameter WORD2 = 'd6;
    parameter WORD3 = 'd7;
    parameter INVALID_DATA = 'd8;
    
    // Constant hexadecimal values with start/stop bits and parity
    parameter ACK = 11'b11111110100;
    parameter RESET = 11'b11111111110;      // 'hFF
    parameter MOUSE_ID = 11'b11000000000;
    parameter BAT_OK = 'hAA;
    parameter EN_REPORTING = 11'b10111101000;
    
    reg [3:0] state, next_state;
    reg [2:0] word_counter;
    reg valid_1, valid_2, valid_3;
    reg [10:0] data_in;                 // internal signal for rx_data assigned at IDLE_REPORTING state
    reg [32:0] full_data;
    // Assigning flags
    assign new_out = (state == WORD3);
    assign write = (state == WRITE_F4);
    
    // 3 Always FSM Style
    always @(posedge reset or posedge clk_25MHz) begin
      if (reset)
        state <= IDLE_RESET;
      else
        state <= next_state;
    end
    
    // next state logic
    always @* begin
      next_state = 3'bx;
      if (reset) begin
        next_state <= IDLE_RESET;
      end
      else begin
        case (state)
          IDLE_RESET: begin
                      if ((rx_data == MOUSE_ID) && data_flag)                next_state = BUSY_CHECK;
                      else                                                   next_state = IDLE_RESET;
          end
          BUSY_CHECK: begin
                      if (!busy && !data_flag)                               next_state = WRITE_F4;
                      else                                                   next_state = BUSY_CHECK;
          end
          WRITE_F4: begin
                      // here the write flag toggles high, and we write F4 command to tx_data line
                      if (write)                                             next_state = WAIT_ACK;
                      else                                                   next_state = WRITE_F4;
          end 
          WAIT_ACK: begin
                      if ((rx_data == ACK) && data_flag)                     next_state = IDLE_REPORTING;
                      else                                                   next_state = WAIT_ACK;
          end
          IDLE_REPORTING: begin
                      if (data_flag)                                         next_state = WORD1;
                      else                                                   next_state = IDLE_REPORTING;
          end
          WORD1: begin
                      // stay here until all 11 bits are shifted into word1 reg
                      if (data_flag && valid_1 && (word_counter == 2))       next_state = WORD2;
                      else if (data_flag && !valid_1 && (word_counter == 2)) next_state = INVALID_DATA;
                      else                                                   next_state = WORD1;
          end
          WORD2: begin
                      if (data_flag && valid_2 && (word_counter == 3))       next_state = WORD3;
                      else if (data_flag && !valid_2 && (word_counter ==3))  next_state = INVALID_DATA;
                      else                                                   next_state = WORD2;
          end
          WORD3: begin
                      if (!data_flag && valid_3)                             next_state = IDLE_REPORTING;
                      else if (data_flag && !valid_3)                        next_state = INVALID_DATA;
                      else                                                   next_state = WORD3;
          end
          INVALID_DATA: begin
                                                                             next_state = IDLE_REPORTING;
          end
          default: begin
                                                                             next_state = IDLE_RESET;
          end
        endcase
      end
    end
    
    // sequential  logic
    always @ (posedge reset or posedge clk_25MHz) begin
      // initialize variables
      if (reset) begin
        data_in <= 11'b10101010101;
        word_counter <= 0;
        valid_1 <= 1'b0;
        valid_2 <= 1'b0;
        valid_3 <= 1'b0;
        F4_command <= 11'b10101010101;
       // y_speed <= 8'b00000000;
      end
      else begin
        // default values again
        data_in <= 11'b10101010101;
        word_counter <= 0;
        valid_1 <= 1'b0;
        valid_2 <= 1'b0;
        valid_3 <= 1'b0;
        F4_command <= EN_REPORTING;
        //y_speed <= 8'b00000000;
        
        full_data <= full_data;
        case (next_state)
          IDLE_RESET: begin
                        // no sequential logic here
                        data_in <= rx_data;
                      end
          BUSY_CHECK: begin
                        // no sequential logic here, waiting on inputs to update
                        data_in <= rx_data;
                      end
          WRITE_F4: begin
                      // make F4_command = ENABLE_REPORTING
                      F4_command <= EN_REPORTING;
                    end
          WAIT_ACK: begin
                      // waiting on data_in, 
                    end
          IDLE_REPORTING: begin
                            // like a soft reset, getting ready to report words
                            data_in <= rx_data;
                          end
          WORD1: begin
                  data_in <= rx_data;
                  if ((data_in[3] == 0) && (data_in[4] == 1) && !err) begin
                    valid_1 <= 1'b1;
                  end
                  else
                    valid_1 <= 1'b0;
                  // grab y-dir and y-max-speed
                     /* if (state == IDLE_REPORTING) begin
                    y_dir <= rx_data[6];
                    y_max_speed <= rx_data[8];
                  end
                  else begin
                    y_dir <= y_dir;
                    y_max_speed <= y_max_speed;
                  end*/
                  word_counter <= 'd2; 
                  
                  if (data_flag)
                     full_data[10:0] <= rx_data;
                end
          WORD2: begin
                  data_in <= rx_data;
                  // don't care to check tho just move the state
                  if (!err)                     valid_2 <= 1'b1;
                  else                          valid_2 <= 1'b0;
                  word_counter <= 'd3;
                  
                  if (data_flag)
                      full_data[21:11] <= rx_data;
          end
          WORD3: begin
                data_in <= rx_data;
                // new out is already flagged high when it reaches this state, may need to change it
                // check parity
                if (!err) begin
                 // y_speed <= rx_data[8:1];
                  valid_3 <= 1'b1;
                end
                else begin
                  valid_3 <= 1'b0;
              //    y_speed <= y_speed;
                end
                
                if (data_flag)
                   full_data[32:22] <= rx_data;
          end
          INVALID_DATA: begin
            // no sequential logic, just need to switch states from words to idle_reporting
          end
        endcase
      end
    end
    
    assign y_dir = full_data[6];
    assign y_max_speed = full_data[8];
    assign y_speed = y_dir ? ~full_data[30:23] + 1 :full_data[30:23];
   /* reg y_dir1, y_dir2, y_dir3,y_max1, y_max2;
    // y-Dir pipeline
    always @ (posedge data_flag) begin
       y_dir1 <= rx_data[6];
       //y_dir2 <= y_dir1;
       y_dir <= y_dir1;
       
    end
      // y-max-speed pipeline
    always @ (posedge data_flag) begin
       y_max1 <= rx_data[8];
      // y_max2 <= y_max1;
       y_max_speed <= y_max1; 
    end*/
endmodule