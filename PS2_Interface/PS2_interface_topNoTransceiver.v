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
        
        reg [10:0] special_command;                                             //holds special commands (eg: enable reporting)
        reg [3:0] special_counter;                                              //counter for special commands
        
        
        // Always block that controls transmitting to the mouse


        always @(posedge ps2_clk or posedge reset) begin
            // Conduct valid checker : check if the start and/or stop bits are correct for each word in MSB
            if (reset) begin
                error_flag <= 0;
                paddle_dir <= 0;
                paddle_speed <= 0;
            end
            else if (ps2_data[32] == 0) begin                                        // stop bit, third word
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