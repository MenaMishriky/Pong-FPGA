// This module interprets the clock and data input signals from the mouse using PS/2 interface microcontroller on the Basys 3
module mouse_ps2(
    input clock_100Mhz,
    input reset,
    input mouse_data,
    input mouse_clk,
    output reg [1:0] paddle_speed,      // Block outputs YS bit to hold y- paddle speed
    output reg [7:0] paddle_dir,        // Block outputs Y0 - Y7 bits to hold y- paddle dir
    );
    reg [5:0] mouse_bits;
    reg [26:0] one_second_counter;
    wire one_second_enable;
    // Counting # of bits recieved from the mouse data; 33 bits to be received
    always @(posedge mouse_clk or posedge reset)
    begin
        if (reset == 1)
            mouse_bits <= 0;
        else if (mouse_bits <= 31)
            mouse_bits <= mouse_bits  + 1;
        else
            mouse_bits <= 0;
    end
endmodule