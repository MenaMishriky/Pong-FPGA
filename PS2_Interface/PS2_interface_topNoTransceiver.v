// This module is responsible for decoding the signals from the mouse and converting them to decimal values
// for the paddle direction and paddle speed.
// 5 main functionalities:
// 1. Transmit special commands to the mouse for data reporting to feed into data_in
// 2. Decode mouse signals (if all 3 words arrive and are 11 bits in length) and store in registers
// 3. Raise an error flag if the start and/or stop bits of each word is incorrect
// 4. Raise a new_output_flag when a new speed/dir is available, then goes low when after 1 cycle
// 5. Convert bits into paddle direction and paddle speed
`timescale 1ns / 1ps
module mouse_ps2_verilog( input wire clk_25MHz,
                        input wire ps2_clk,
                        input wire data_in,
                        input wire reset,
                        output reg paddle_dir,
                        output reg [7:0] paddle_speed,
                        output reg error_flag,
                        output reg new_output_flag);
        reg [32:0] ps2_data;                                                    // big register to hold 33-bit mouse data
        reg [5:0] bit_counter;                                                  // 0-33 counter to make sure all bits are present
        reg new_output_history;                                                 // flag history to validate that new output is indeed present
        
        reg [10:0] special_command_in;                                          //holds special commands received (eg: acknowledge)
        reg [10:0] special_command_out;                                         //holds special commands to be sent (eg: enable data reporting)
        reg [3:0] special_counter;                                              //counter for special commands
        reg [1:0] state;
        reg [1:0] next_state;                                                     
        wire ID_received, Ack_received;                                         //Ack_received is after Enable reporting
        reg data_out;

        localparam READ_SP = 2'b00;
        localparam WRITE_SP = 2'b01;
        localparam READ_DATA = 2'b11;
        localparam DATA_EN_REPORT = 8'hF4;
        localparam ACK = 8'hFA;
        localparam ID = 8'h00;
        
        // Always block containing state machine that controls how states are changed
        always @(reset, ID_received, Ack_received, state) begin
            if (reset) begin
                next_state <= READ_SP;
                special_command_out <= 11'b00000000010;
            end
            else begin
                case (state)
                    READ_SP       :  begin                                         // case 1: BAT passed, streaming mode enabled, do nothing
                                        next_state = ID_received ? WRITE_SP : READ_SP;
                                    end
                    WRITE_SP      : begin                                          // case 2: mouse_ID received, write data enable reporting
                                        next_state = Ack_received ? READ_DATA : READ_SP; 
                                    end
                    READ_DATA     : begin                                          // case 3: mouse ack received, read ps2_data and ps2_clk, do nothing
                                        next_state = READ_DATA;
                                    end                                                                 
                endcase
            end
                 
        end

        // Always block containing state machine that controls when states are changed
        always @(posedge reset or posedge ps2_clk or negedge ps2_clk) begin
            if (reset) begin
                state <= READ_SP;
                special_command_in <= 11'b00000000010;
                special_command_out <= {1'b1,1'b1,DATA_EN_REPORT,1'b0}; //stop, parity, data, start
                special_counter <= 0;
            end
            else begin
                case (state)
                    READ_SP       :  begin                                         // case 1: BAT passed, streaming mode enabled, do nothing
                                        if(!ps2_clk) begin
                                            
                                        end
                                    end
                    WRITE_SP      : begin                                          // case 2: on posedge ps2_clk, shift special_command_out to data_in
                                        if(ps2_clk) begin                          
                                            data_out <= special_command_out[0];     
                                            special_command_out[9:0] <= special_command_out[10:1];
                                            if (special_counter < 11) begin
                                                special_counter <= special_counter + 1;
                                            end
                                            else
                                                special_counter <= 1;
                                        end
                                    end
                    READ_DATA     : begin                                          // case 3: mouse ack received, read ps2_data and ps2_clk, do nothing
                                        
                                    end                                                                 
                endcase
            end    
        end

        // Always block for valid bit checker : check if the start and/or stop bits are correct for each word in MSB
        always @(posedge ps2_clk or posedge reset) begin
            if (reset) begin
                error_flag <= 0;
                paddle_dir <= 0;
                paddle_speed <= 0;
            end
            else if (ps2_data[32] == 0) begin                                   // stop bit, third word
                error_flag <= 1;
            end
            else if (ps2_data[22] == 1)                                         // start bit, third word
                error_flag <= 1;
            else if (ps2_data[21] == 0)                                         // stop bit, second word
                error_flag <= 1;
            else if (ps2_data[11] == 1)                                         // start bit, second word
                error_flag <= 1;
            else if (ps2_data[10] == 0)                                         // stop bit, first word
                error_flag <= 1;
            else if (ps2_data[4] == 0)                                          // bit 4 must be 1, first word
                error_flag <= 1;
            else if (ps2_data[3] == 1)                                          // bit 3 must be 0, first word
                error_flag <= 1;
            else if (ps2_data[0] == 1)                                          // start bit, first word
                error_flag <= 1;
            else
                error_flag <= 0;                
        end
        
        // Always block responsible for shifting the mouse data into the register
        always @(negedge ps2_clk or posedge reset) begin
            // Initialize
            if (reset) begin
                ps2_data <= 0;
                bit_counter <= 0;
            end
            else begin
                // Assign data_in to ps2_data by shifting right (LSB)
                ps2_data[32] <= data_in;
                ps2_data[31:0] <= ps2_data[32:1];
                // Check if all data is received, counter should have 33 bits
                if (bit_counter < 33) begin
                    bit_counter <= bit_counter + 1;
                end
                else
                    bit_counter <= 1;                                               // received all bits
            end
        end

        // Always block responsible for checking new output is valid 
        always @(posedge clk_25MHz or posedge reset) begin
            if (reset) begin
               new_output_flag <= 0;
               new_output_history <= 0;
            end
            else if((bit_counter == 0) || (bit_counter == 1)) begin
                new_output_flag <= 0;
                new_output_history <= 0;
            end
            else if( (bit_counter == 33)&&(!error_flag)&&(!new_output_history)) begin
                new_output_flag <= 1'b1;
                new_output_history <= 1'b1;
            end
            else
                new_output_flag <= 1'b0;
             
           // Convert binary to decimal values and parse paddle speed and paddle direction
           paddle_speed <= ps2_data[8] ? 8'hff : ps2_data[30:23];
           paddle_dir <= ps2_data[6]; 
        end
endmodule