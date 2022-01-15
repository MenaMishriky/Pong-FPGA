// This module is responsible for decoding the signals from the mouse and converting them to decimal values
// for the paddle direction and paddle speed.
// 4 main functionalities:
// 1. Decode mouse signals (if all 3 words arrive and are 11 bits in length) and store in registers
// 2. Raise an error flag if the start and/or stop bits of each word is incorrect
// 3. Raise a new_output_flag when a new speed/dir is available, then goes low when after 1 cycle
// 4. Convert bits into paddle direction and paddle speed
// TO DO: remake always block for new_output_flag
`timescale 1ns / 1ps
module mouse_ps2_verilog( input wire clk_25MHz,
                       input wire clk,
                       input wire data_in,
                       input wire reset,
                       output reg paddle_dir,
                       output reg [7:0] paddle_speed,
                       output reg error_flag,
                       output reg new_output_flag);
        reg [32:0] ps2_data;                                                    // big register to hold 33-bit mouse data
        reg [5:0] bit_counter;                                                  // 0-33 counter to make sure all bits are present
        
        always @(negedge ps2_data) begin
            // Assign data_in to ps2_data by shifting right (LSB)
            ps2_data[32] <= data_in;
            ps2_data[31:0] <= ps2_data[32:1];
            // Check if all data is received, counter should have 33 bits
            if (bit_counter < 32) begin
                bit_counter <= bit_counter + 1;
            end
            else
                bit_counter <= 0;                                               // received all bits
            // Conduct valid checker : check if the start and/or stop bits are correct for each word
            if (ps2_data[32] == 1) begin                                        // start bit, first word
                error_flag <= 1;
            end
            else if (ps2_data[22] == 0)                                         // stop bit, first word
                error_flag <= 1;
            else if (ps2_data[21] == 1)                                         // start bit, second word
                error_flag <= 1;
            else if (ps2_data[11] == 0)                                         // stop bit, second word
                error_flag <= 1;
            else if (ps2_data[10] == 1)                                         // start bit, third word
                error_flag <= 1;
            else if (ps2_data[0] == 0)                                          // stop bit, third word
                error_flag <= 1;
            else
                error_flag <= 0;
                
            // Convert binary to decimal values and parse paddle speed and paddle direction
            paddle_speed <= ps2_data[9:2];
            paddle_dir <= ps2_data[26];
        end
        
        always @(posedge clk_25MHz) begin
            // Lower flag
            new_output_flag = 0;
         end
         
        always @(posedge clk_25MHz) begin
            // Raise new output flag if error flag is == 0 && bit_counter
            if (error_flag == 0)
                new_output_flag = 1;
        end
endmodule
