/* This module is a testbench for both the mouse_ctrl.v and ps2_interface_low_level.v (aka the PS2 Interface Mouse Receiver and Intepreter).
   It will be responsible for taking the data given to it by the PS2_interface.v (PS2 Mouse Transceiver)
   and outputting the proper results, i.e. paddle speed, direction, and overflow
   as well as correctly writing the F4 command to the mouse.
 
    1) RESET EVERYTHING
    2) INSTANTIATE MOUSE OBJECT
    3) PUT INPUTS / OUTPUTS
    INPUTS:
    - After 5 us, mouse object send device ID
    - Mouse object should be able to receive F4 command
    - Mouse object checks F4 command, should start reporting actual data, i.e. every 10 us send the 3 packets
    - Gives this data to mouse_ctrl module
    OUTPUTS:
    - mouse_ctrl module outputs speed, direction, and overflow
    - Make a checker to see if this is the speed, direction, and overflow data we expect based on the 3 packets
        > Checker is going to independently check the data results and compare to design
    USE FROM MENA'S TB:
    - packet_class
    - receive_data for F4 command
    - send_packet for the 3 packets, call it 3 times since each is 11 bits ; wait for mouse_sending status bit to go low
*/

// Packet Class : constructs a random 33bit packet. The validity of the packet's parity depends on valid_x
class Packet_Class#(bit valid_x =1); // 33bit packet for the PS2 interface

    bit [10:0] first_word;// MSB First, so Stop, parity, YY, XY YS, XS, 1, 0 R, L , Start
    bit start1, stop1,P1;
    bit [7:0] X_speed;
    bit start2, stop2, P2;
    bit [7:0] Y_speed;
    bit valid;
    
    bit parity0;
    bit [5:0] random_bits;
    function new ();
            this.valid = valid_x;
            random_bits = $urandom_range(64);

            if($countones({random_bits[3:0],2'b10, random_bits[5:4]}) %2) begin
              parity0 = valid? 1'b0:1'b1;
            end
            else begin
              parity0 = valid? 1'b1:1'b0;
            end
            
            this.first_word = {1'b1, parity0, random_bits[3:0],2'b10, random_bits[5:4], 1'b0};
            this.start1 = 1'b0;
            this.X_speed = $urandom_range(0,256) ;
            
            if($countones(X_speed) %2) begin
              this.P1 = valid? 1'b0:1'b1;
            end
            else begin
              this.P1 = valid? 1'b1:1'b0;
            end
           
            this.stop1 = 1'b1;
            this.start2 = 1'b0;
            this.Y_speed =$countones(Y_speed) % 2? 1'b0:1'b1;
           
            if($countones(Y_speed) %2) begin
              this.P2 = valid? 1'b0:1'b1;
            end
            else begin
              this.P2 = valid? 1'b1:1'b0;
            end
           
            this.stop2 = 1'b1;
    endfunction
    
endclass

// Mouse_ctrl Class : Modified version of mouse_class (see Sim_low_level.sv) that fits the testbench's objective
class Mouse_Ctrl_Class;
    bit mouse_sending, mouse_receiving;
    logic [10:0] mouse_ID, mouse_ACK;
    logic [10:0] receive_F4;
    logic data_flag, busy;

    int data_in_counter;
    int data_out_counter;

    function new();
        this.mouse_sending = 1'b0;
        this.mouse_receiving = 1'b0;
        this.data_flag = 1'b0;
        this.busy = 1'b0;
        this.mouse_ID = 11'b11000000000;               // Stop, parity, ID, start
        this.mouse_ACK = 11'b11111110100;              // Stop, parity, ACK, start
        this.receive_F4 = 11'b11000000000;             // Mouse should receive F4, see task receive_data
        this.data_in_counter = 0;
        this.data_out_counter = 0;
        $display("Creating new mouse object. The variable is %d", mouse_ID);
   endfunction 

    // This task is for the mouse to receive the F4 command from the UUT
    task receive_data; // Called when a negative clock edge is detected and mouse is not sending
        $display("TASK: MOUSE: RECEIVE DATA");
        mouse_receiving = 1'b1;   
        //controlling status bits to help with assertions
        delay100 = 1;
        #100000;//wait 100 micro. assert in top module that data doesnt go down here
        #40;//1 clk25MHz room
        delay100 = 0;
        delay20 = 1;
        #20000;
        #40;//1 clk25MHz room
        delay20 = 0;
        // Mouse reads the first bit (the start bit)
        data_in_counter = 'd1;
        rx_data[9:0] = rx_data[10:1];
        rx_data[10] = PS2_data_in;
        
        
        //generate clock and start receving data
        fork

            begin: receive
                forever @(posedge Sim_low_level.mouse.PS2_clk_out) begin
            // $display("DEBUG 4");//DEBUG
                //$display("%t: rx = %d", $time, Sim_low_level.mouse.rx_counter);
                if(Sim_low_level.mouse.mouse_receiving) begin
                    if (Sim_low_level.mouse.rx_counter < 11) begin//receive the data bits
                        Sim_low_level.mouse.rx_data[9:0] = Sim_low_level.mouse.rx_data[10:1];
                        Sim_low_level.mouse.rx_data[10] = Sim_low_level.mouse.PS2_data_in;  
                        Sim_low_level.mouse.rx_counter++;
                        if (Sim_low_level.mouse.rx_counter >= 11 && Sim_low_level.rx_data[10]) begin//if we get stop bit
                            if ($countones(Sim_low_level.mouse.rx_data[9:1]) %2) begin //check parity and its correct
                                Sim_low_level.mouse.rx_counter = 0;
                                Sim_low_level.mouse.mouse_sending_ack_bit = 1'b1;
                                Sim_low_level.mouse.mouse_receiving = 0;
                                
                                //send ack bit and end
                                disable generate_rx_clk;
                                Sim_low_level.mouse.PS2_data_out = 1'b0;
                                #25000;
                                Sim_low_level.mouse.PS2_clk_out = 1'b0;
                                #25000;
                                Sim_low_level.mouse.PS2_data_out = 1'b1;
                                Sim_low_level.mouse.PS2_clk_out = 1'b1;
                                Sim_low_level.mouse.mouse_sending_ack_bit = 1'b0;
                                Sim_low_level.mouse.rx_data_available = 1'b1;
                                disable receive;
                            end
                            else begin//if parity is wrong stop everything and dont give ack bit. This doesnt exactly emulate real life, but the purpose here is to see if DUT can detect error of not getting ack
                                #100000; //wait 1 PS2 cycle to simulate giving more clocks to DUT from mouse
                                Sim_low_level.mouse.PS2_data_out = 1'b1;
                                Sim_low_level.mouse.PS2_clk_out = 1'b1;
                                Sim_low_level.mouse.mouse_receiving = 1'b0;
                                disable generate_rx_clk;
                                disable receive;
                            end
                        end
                    end
                end//if(mouse_receving)
                else begin
                    disable receive;
                end
                end //forever look
        end//receive
        
        begin: generate_rx_clk
            forever begin
            //ERROR NOTE: I use hierarchial references to avoid null ptr dereference error since fork generates a new scope
                #25000 Sim_low_level.mouse.PS2_clk_out = ~ Sim_low_level.mouse.PS2_clk_out;//generate the rx clock 
                
            end
        end//generate_rx_clk
        join
   endtask

   // This task drives the UUT and sends it a packet (PS2_Interface to Mouse_Ctrl)
   task send_packet(input [10:0] data);
        $display("Sending packet %h\n", data);
        tx_data = data;   
        mouse_sending = 1'b1;
        //recall that the idle state is when data and clock are 1
        PS2_data_out = 1'b0;
        #25000;//wait one clock half cycle
        PS2_clk_out = 1'b0; //send the start bit on this negedge

        
        tx_data [9:0] = tx_data [10:1]; //start bit already sent just now , so shift data
        
        if(mouse_receiving)
        $display("SENDING WHILE RECEIVING PROBLEM\n");
        
        fork
        begin: generate_clock
            forever begin
                #25000 Sim_low_level.mouse.PS2_clk_out = !Sim_low_level.mouse.PS2_clk_out;
                //$display("shifting clock. mouse sending is %d", Sim_low_level.mouse.mouse_sending);//DEBUG
                
                if(!Sim_low_level.mouse.mouse_sending) begin
                disable generate_clock;      
                $display("DISABLED CLOCK!!!");//DEBUG
                end
            end
        end
        
        begin: shift_data_out //send the rest of data, by default F4
            //$display("tx counter is %d", Sim_low_level.mouse.tx_counter);
            forever @(posedge Sim_low_level.mouse.PS2_clk_out) begin
            if (Sim_low_level.mouse.tx_counter < 10) begin
                Sim_low_level.mouse.PS2_data_out = Sim_low_level.mouse.tx_data[0];
                Sim_low_level.mouse.tx_data[9:0] = Sim_low_level.mouse.tx_data[10:1];
                Sim_low_level.mouse.tx_counter = Sim_low_level.mouse.tx_counter + 1;
                //$display("tx counter is %d", Sim_low_level.mouse.tx_counter);
            end
            else begin
                Sim_low_level.mouse.tx_counter = 0;
                disable generate_clock;
                //$display("(2) DISABLED CLOCK!!!");//DEBUG
                disable shift_data_out;             
            end
            end//forever
        end //shift_data_out
        join
        
        PS2_clk_out = 1'b1;
        PS2_data_out = 1'b1;
        mouse_sending = 1'b0;
        $display("Exiting send packet task");//DEBUG
   endtask

endclass

module mouse_ctrl_tb();

    // UUT Inputs
    reg clk_25MHz_tb;
    reg reset_tb;
    reg [10:0] rx_data_tb;
    reg data_available_tb;
    reg busy_tb;
    reg err_tb;

    // UUT Outputs
    wire y_dir_tb;
    wire y_max_speed_tb;
    wire [7:0] y_speed_tb;
    wire new_out_tb;
    wire [10:0] F4_command_tb;
    wire write_tb;

    // UUT Internal Signals 
    // PS2 Interface Outputs are my inputs
    // Mouse Ctrl Outputs are his inputs
    reg [10:0] data;                                // Data to send from PS2 interface to the UUT
  
    // Instantiation of mouse, packet, and UUT
    Mouse_Ctrl_Class mouse = new();
    Packet_Class packet = new();                    // Create rand packet (valid)
    mouse_ctrl_tb UUT ( clk_25MHz_tb,
                        reset_tb;
                        rx_data_tb;
                        data_available_tb;
                        busy_tb;
                        err_tb;
                        y_dir_tb;
                        y_max_speed_tb;
                        y_speed_tb;
                        new_out_tb;
                        F4_command_tb;
                        write_tb;
                    );

    // Reset everything
    initial begin
        reset_tb = 1'b0;
        clk_25MHz_tb = 1'b1;
        data_available_tb = 1'b0;
        rx_data_tb = 11'b10101010101;               //Initialized to a garbage value
        #50;
        rx_data_tb = mouse.ID;                      // After 5 us, sends mouse device ID
    end

    always #20 clk_25MHz = ~clk25MHz;

    // Mouse sends ACK byte back to UUT
    // Mouse starts reporting data
endmodule