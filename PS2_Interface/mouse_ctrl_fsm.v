module mouse_ctrl_fsm ( input wire clk_25MHz,
                    input wire reset,
                    input [10:0] rx_data,
                    input wire data_flag,
                    input wire busy,
                    input wire err,
                    output reg y_dir,
                    output reg y_max_speed,
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
parameter RESET = 11'b11111111110;      // 'hFF
parameter MOUSE_ID = 11'b11000000000;
parameter BAT_OK = 'hAA;
parameter EN_REPORTING = 11'b10111101000;

reg [3:0] state, next_state;
reg [2:0] word_counter;
reg valid_1, valid_2, valid_3;
reg [10:0] data_in;                 // internal signal for rx_data assigned at IDLE_REPORTING state

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
    y_speed <= 8'b00000000;
  end
  else begin
    // default values again
    data_in <= 11'b10101010101;
    word_counter <= 0;
    valid_1 <= 1'b0;
    valid_2 <= 1'b0;
    valid_3 <= 1'b0;
    F4_command <= EN_REPORTING;
    y_speed <= 8'b00000000;
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
              // check if bits 7, 6 (or bits 3, 4 depending on shifting) are 0,1 and parity bit = 0
              if ((data_in[3] == 0) && (data_in[4] == 1) && !err) begin
                valid_1 <= 1'b1;
              end
              else
                valid_1 <= 1'b0;
              // grab y-dir and y-max-speed
              y_dir <= data_in[4];
              y_max_speed <= data_in[8];
              word_counter <= 'd2; 
            end
      WORD2: begin
              data_in <= rx_data;
              // don't care to check tho just move the state
              if (!err)                     valid_2 <= 1'b1;
              else                          valid_2 <= 1'b0;
              word_counter <= 'd3;
      end
      WORD3: begin
            data_in <= rx_data;
            // new out is already flagged high when it reaches this state, may need to change it
            // check parity
            if (!err) begin
              y_speed <= data_in;
              valid_3 <= 1'b1;
            end
            else                            valid_3 <= 1'b0;
      end
      INVALID_DATA: begin
        // no sequential logic, just need to switch states from words to idle_reporting
      end
    endcase
  end
end
endmodule