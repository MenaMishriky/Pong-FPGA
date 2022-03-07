module mouse_ctrl_fsm ( input wire clk_25MHz,
                    input wire reset,
                    input [10:0] rx_data,
                    input data_available,
                    input busy,
                    input err,
                    output reg y_dir,
                    output reg [7:0] y_speed,
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
parameter RESET = 'hFF;
parameter MOUSE_ID = 'h00;
parameter BAT_OK = 'hAA;
parameter EN_REPORTING = 11'b10111101000;

reg [3:0] state, next_state;
reg [2:0] word_counter;
reg valid_1, valid_2, valid_3;
reg bad_data;
reg [3:0] bit_counter;
reg [10:0] data_in;                 // internal signal for rx_data assigned at IDLE_REPORTING state
reg data_flag;

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
  data_flag = 1'b0;
  if (reset) begin
    next_state <= IDLE_RESET;
  end
  else begin
    case (state)
      IDLE_RESET: begin
                  if ((data_in == MOUSE_ID) && data_flag)                next_state = BUSY_CHECK;
                  else                                                   next_state = IDLE_RESET;
      end
      BUSY_CHECK: begin
                  if (!busy && !data_flag)                               next_state = WRITE_F4;
                  else if (busy && !data_flag)                           next_state = BUSY_CHECK;
      end
      WRITE_F4: begin
                  // here need to toggle write to high, and shift in the F4 command to tx_data
                  // What does the FSM need to control here? How does it know to move on to WAIT_ACK?
                  if (write)                                             next_state = WAIT_ACK;
                  else                                                   next_state = WRITE_F4;
      end 
      WAIT_ACK: begin
                  if ((data_in == ACK) && data_flag)                     next_state = IDLE_REPORTING;
                  else                                                   next_state = WAIT_ACK;
      end
      IDLE_REPORTING: begin
                  // How will idle_reporting differentiate between word1 and word2 in state machine?
                  if (data_flag)                                         next_state = WORD1;
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
                  if (!valid_1)                                          next_state = IDLE_REPORTING;
                  else if (!valid_2)                                     next_state = IDLE_REPORTING;
                  else if (!valid_3)                                     next_state = IDLE_REPORTING;
                  else                                                   next_state = IDLE_REPORTING;
      end
      default: begin
                  next_state = IDLE_RESET;
               end
    endcase
  end
end

// combinational logic
always @ (posedge reset or posedge clk_25MHz) begin
  // initialize variables
  if (reset) begin
    data_in <= 11'b10101010101;
    data_flag <= 1'b0;
    word_counter <= 0;
    valid_1 <= 1'b0;
    valid_2 <= 1'b0;
    valid_3 <= 1'b0;
    F4_command <= 11'b10101010101;
    bad_data <= 1'b0;
    y_speed <= 8'b00000000;
    bit_counter <= 0;
  end
  else begin
    // default values again
    data_in <= 11'b10101010101;
    data_flag <= 1'b0;
    word_counter <= 0;
    valid_1 <= 1'b0;
    valid_2 <= 1'b0;
    valid_3 <= 1'b0;
    F4_command <= 11'b10101010101;
    bad_data <= 1'b0;
    y_speed <= 8'b00000000;
    bit_counter <= 0;
    case (next_state)
      IDLE_RESET: begin
                    // no combinational logic here
                  end
      BUSY_CHECK: begin
                    // no combinational logic here, waiting on inputs to update
                  end
      WRITE_F4: begin
                  // set write to high, make F4_command = ENABLE_REPORTING
                  // shift data right from F4_command to tx_data on PS2_block coming in from left
                  bit_counter <= bit_counter + 1;
                  F4_command[10] <= EN_REPORTING;
                  F4_command[9:0] <= F4_command[10:1];
                end
      WAIT_ACK: begin
                  // waiting on data_in
                  // shifting data right in from data_in coming from left?
                  bit_counter <= bit_counter + 1;
                  data_in[10] <= data_in;
                  data_in[9:0] <= data_in[10:1];
                end
      IDLE_REPORTING: begin
                        // like a soft reset, getting ready to report words
                      end
      WORD1: begin
              // shift data_in
              bit_counter <= bit_counter + 1;
              data_in[10] <= data_in;
              data_in[9:0] <= data_in[10:1];
              // check if bits 7, 6 (or bits 3, 4 depending on shifting) are 0,1 and parity bit = 0
              if ((data_in[7] == 0) && (data_in[6] == 1) && (data_in[1] == 0
              )) begin
                valid_1 <= 1'b1;
              end
              else
                valid_1 <= 1'b0;
              // grab y-dir
              y_dir <= data_in[4];
              // Y-direction overflow bit necessary? I forgot ...
              word_counter <= 'd2; 
            end
      WORD2: begin
              // shift data_in (X-axis)
              bit_counter <= bit_counter + 1;
              data_in[10] <= data_in;
              data_in[9:0] <= data_in[10:1];
              // don't care to check tho just move the state
              if (data_in[1] == 0)          valid_2 <= 1'b1;
              else                          valid_2 <= 1'b0;
              word_counter <= 'd3;
      end
      WORD3: begin
            // shift data_in (Y-axis)
            bit_counter <= bit_counter + 1;
            data_in[10] <= data_in;
            data_in[9:0] <= data_in[10:1];
            // check parity
            if (data_in[1] == 0) begin
              bit_counter <= 0;             // restart bit counter
              // shift right data_in into y_speed coming in from left
              bit_counter <= bit_counter + 1;
              y_speed[7] <= data_in[9:2];
              y_speed[6:0] <= y_speed[7:1];
              valid_3 <= 1'b1;
            end
            else                            valid_3 <= 1'b0;
      end
      INVALID_DATA: begin
        // no combinational logic, just need to switch states from words to idle_reporting
        // maybe raise a flag
        bad_data <= 1'b1;
      end
    endcase
  end
end
endmodule