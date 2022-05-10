`timescale 1ns / 1ps
/* This module is a testbench for both the mouse_ctrl.v and ps2_interface_low_level.v (aka the PS2 Interface Mouse Receiver and Intepreter).
   It will be responsible for taking the data given to it by the mouse device 
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

//packet class, constructs a random 33bit packet. The validity of the packet's parity depends on valid_x
class Packet_Class#(bit valid_x =1); //33bit packet for the PS2 interface

    bit [10:0] first_word;//MSB First, so Stop, parity, YY, XY YS, XS, 1, 0 R, L , Start
    bit start1, stop1,P1;
    bit [7:0] X_speed;
    bit Y_dir;
    bit Y_max_speed;
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

class mouse_class;
   bit mouse_sending, mouse_receiving, mouse_sending_ack_bit;
   logic PS2_data_in, PS2_data_out, PS2_clk_in, PS2_clk_out;//inputs and outputs to class, to be connected to UUT
   logic[10:0] rx_data; //received data
   logic[10:0] tx_data;
   logic rx_data_available;
   logic [10:0] F4;//stop, parity, F, 4, start
   
   logic delay100, delay20;//status bits
   int rx_counter;
   int tx_counter;
   
   function new();
     this.mouse_sending = 1'b0;
     this.mouse_receiving = 1'b0;
     this.mouse_sending_ack_bit = 1'b0;
     this.PS2_data_in = 1'bz;
     this.PS2_data_out = 1'b1;
     this.PS2_clk_in = 1'bz;
     this.PS2_clk_out = 1'b1;
     this.rx_data_available = 1'b0;
     this.F4 = 11'b10111101000; //stop, parity, F, 4, start
     this.delay100 = 0;
     this.delay20 = 0;
     this.rx_counter = 0;
     this.tx_counter = 0;
     $display("Creating new mouse object. The damn variable is %d", PS2_clk_out);
   endfunction
   
   task receive_data; //called when a negative clock edge is detected and mouse is not sending
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
     
     //when the UUT releases clock, mouse reads the first bit (the start bit)
     rx_counter = 'd1;
     rx_data[9:0] = rx_data[10:1];
     rx_data[10] = PS2_data_in;
     
     
     //generate clock and start receving data
     fork
 
         begin: receive
             forever @(posedge big_ps2_tb.mouse.PS2_clk_out) begin
            // $display("DEBUG 4");//DEBUG
             //$display("%t: rx = %d", $time, big_ps2_tb.mouse.rx_counter);
               if(big_ps2_tb.mouse.mouse_receiving) begin
                   if (big_ps2_tb.mouse.rx_counter < 11) begin//receive the data bits
                       big_ps2_tb.mouse.rx_data[9:0] = big_ps2_tb.mouse.rx_data[10:1];
                       big_ps2_tb.mouse.rx_data[10] = big_ps2_tb.mouse.PS2_data_in;  
                       big_ps2_tb.mouse.rx_counter++;
                       if (big_ps2_tb.mouse.rx_counter >= 11 && big_ps2_tb.UUT.ps2.rx_data[10]) begin//if we get stop bit
                           if ($countones(big_ps2_tb.mouse.rx_data[9:1]) %2) begin //check parity and its correct
                              big_ps2_tb.mouse.rx_counter = 0;
                              big_ps2_tb.mouse.mouse_sending_ack_bit = 1'b1;
                              big_ps2_tb.mouse.mouse_receiving = 0;
                              
                              //send ack bit and end
                              disable generate_rx_clk;
                              big_ps2_tb.mouse.PS2_data_out = 1'b0;
                              #25000;
                              big_ps2_tb.mouse.PS2_clk_out = 1'b0;
                              #25000;
                              big_ps2_tb.mouse.PS2_data_out = 1'b1;
                              big_ps2_tb.mouse.PS2_clk_out = 1'b1;
                              big_ps2_tb.mouse.mouse_sending_ack_bit = 1'b0;
                              big_ps2_tb.mouse.rx_data_available = 1'b1;
                              disable receive;
                           end
                           else begin//if parity is wrong stop everything and dont give ack bit. This doesnt exactly emulate real life, but the purpose here is to see if UUT can detect error of not getting ack
                              #100000; //wait 1 PS2 cycle to simulate giving more clocks to UUT from mouse
                              big_ps2_tb.mouse.PS2_data_out = 1'b1;
                              big_ps2_tb.mouse.PS2_clk_out = 1'b1;
                              big_ps2_tb.mouse.mouse_receiving = 1'b0;
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
              #25000 big_ps2_tb.mouse.PS2_clk_out = ~ big_ps2_tb.mouse.PS2_clk_out;//generate the rx clock 
             
          end
        end//generate_rx_clk
     join
   endtask
   
   
   //This task drives the UUT and sends it a packet (Mouse to PS2_interf)
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
             #25000 big_ps2_tb.mouse.PS2_clk_out = !big_ps2_tb.mouse.PS2_clk_out;
             //$display("shifting clock. mouse sending is %d", big_ps2_tb.mouse.mouse_sending);//DEBUG
             
             if(!big_ps2_tb.mouse.mouse_sending) begin
               disable generate_clock;      
               $display("DISABLED CLOCK!!!");//DEBUG
             end
         end
       end
       
       begin: shift_data_out //send the rest of data, by default F4
          //$display("tx counter is %d", big_ps2_tb.mouse.tx_counter);
          forever @(posedge big_ps2_tb.mouse.PS2_clk_out) begin
            if (big_ps2_tb.mouse.tx_counter < 10) begin
              big_ps2_tb.mouse.PS2_data_out = big_ps2_tb.mouse.tx_data[0];
              big_ps2_tb.mouse.tx_data[9:0] = big_ps2_tb.mouse.tx_data[10:1];
              big_ps2_tb.mouse.tx_counter = big_ps2_tb.mouse.tx_counter + 1;
              //$display("tx counter is %d", big_ps2_tb.mouse.tx_counter);
            end
            else begin
               big_ps2_tb.mouse.tx_counter = 0;
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

class compare_class;
    // Task is to compare the input given from the mouse device to the output of the mouse_ctrl design module 
    task compare_y_dir (input exp, input received);
        if (exp == received)
            $display("%t SUCCESS: Y direction is correct", $time);
    endtask
    
    task compare_y_speed (input [7:0] exp, input [7:0] received);
        if (exp == received)
            $display("%t SUCCESS: Y speed is correct", $time);
    endtask
    
    task compare_y_max_speed (input exp, input received);
        if (exp == received)
            $display("%t SUCCESS: Y max speed is correct", $time);
    endtask
    
    
endclass

class monitor_class;

    //task to compare two packets and returns if same or not
    task compare_packets (input [10:0] exp, input [10:0] received);      
      if(exp == received)
        $display("%t SUCCESS:Packet successfully compared", $time);
      else
        $display("%t : FAILED: incorrect packet. expected: %h, received: %h",$time, exp, received);    
    endtask
    
endclass

module big_ps2_tb();
  
    task wait_for_20_PS2_cycles;
        $display("%t entering wait task", $time);//debug
        #1250000;
        $display("%t leaving wait task", $time);//debug
    endtask
    
    // UUT Inputs
    reg clk_25MHz;
    wire PS2_clk;
    wire PS2_data;
    reg reset;
    reg [10:0] data;
    reg [10:0] tx_data;
    reg wr_en;

    // UUT Outputs
    wire y_dir;
    wire y_max_speed;
    wire [7:0] y_speed;
    wire new_out;
    wire [10:0] F4_command;
    wire write;
    
    wire [7:0] x;
    // UUT Internal Signals 
    // PS2 Interface Outputs are my Inputs 
    // Mouse Ctrl Outputs are his Inputs 
    reg PS2_data_drive, PS2_clk_drive;
    
    // Instantiation of mouse, packet, and UUT 
    mouse_class mouse = new();
    Packet_Class packet = new();
    compare_class compare = new();
    monitor_class monitor = new();
    
    Physics_top PUT (.paddle0_speed(y_speed),
                 .paddle0_dir(y_dir_buffer),
                 .new_data(new_out),
                 .clk_25MHz(clk_25MHz),
                 .reset(reset),
                 .paddle0_pos(x)
                 );
    
    big_ps2 UUT    (.PS2_clk(PS2_clk),
                    .PS2_data(PS2_data),
                    .clk_25MHz(clk_25MHz),
                    .reset(reset),
                    .tx_data(tx_data),
                    .y_dir(y_dir),
                    .y_max_speed(y_max_speed),
                    .y_speed(y_speed),
                    .new_out(new_out),
                    .F4_command(F4_command),
                    .write(write)
                    );
                    
    //in real life,  if the interface writes to the clk, the mouse subits. interface is master
    assign PS2_clk = UUT.ps2.write_to_clk? 1'bz: (mouse.mouse_sending | mouse.mouse_receiving| mouse.mouse_sending_ack_bit)? PS2_clk_drive: 1'b1;//the last 1'b1 is the pullup resistor behavior
    assign PS2_data = UUT.ps2.write_to_data? 1'bz: (mouse.mouse_sending | mouse.mouse_receiving | mouse.mouse_sending_ack_bit)? PS2_data_drive: 1'b1;//the last 1'b1 is the pullup resistor behavior

    integer i;   
    // Reset everything
    initial begin
        reset = 1'b0;
        clk_25MHz = 1'b1;
        tx_data = mouse.F4;
        wr_en = 1'b0;
        #1000; 
        reset = 1'b1;
        #1000; 
        reset = 1'b0;
        #1000;  
                
    //send mouseID from UUT to mouse to enable data reporting
    mouse.send_packet(UUT.ctrl.MOUSE_ID);
    
    fork
        mouse.receive_data();
    join_none
    
    //wait for mouse to receive F4 or timeout
    fork
                
          wait(mouse.rx_data_available);
          
          wait(big_ps2_tb.UUT.ps2.err == 1'b1);
           
          wait_for_20_PS2_cycles();
         
    join_any
    disable fork;

    //compare what mouse received with F4. if correct, we now need to send movement data from mouse to DUT
      if(mouse.rx_data_available) begin
         monitor.compare_packets(mouse.F4, mouse.rx_data);
      end
      else if (big_ps2_tb.UUT.ps2.err) begin
         $display("ERROR in sending data from DUT to mouse, %t", $time);
         $finish;
      end
      else begin
         $display("ERROR TIMEOUT WAITING FOR DUT TO SEND F4 TO MOUSE, %t", $time);
         $finish;
      end
      
      // Send ACK byte to UUT 
      mouse.send_packet(UUT.ctrl.ACK);
   
    // FIRST PACKET
    //sending a 3 word movement packet
    for (i = 0; i < 3; i = i + 1) begin
        if ( i == 0)
            data = 11'b10000010000;//valid packet class
        else if ( i == 1)
            data = {packet.stop1, packet.P1, packet.X_speed, packet.start1};
        else
            data = {packet.stop2, 1'b1, 8'b00000011, packet.start2};
        
        fork
            mouse.send_packet(data);
        join_none//to move on to the next fork (wait for receipt, error or delay) after calling task  
        
        #42; //delay to wait for rx_available to go down
        //wait for receipt, error, or timeout
        fork
            wait(big_ps2_tb.UUT.ps2.err);
        
            wait(big_ps2_tb.UUT.ps2.data_available);
         
            wait_for_20_PS2_cycles();
        join_any
        disable fork;
        
        // DEBUG
        if(big_ps2_tb.UUT.ps2.data_available) begin
            monitor.compare_packets(data, big_ps2_tb.UUT.ps2.rx_data);
        end
      
      else if (big_ps2_tb.UUT.ps2.err) begin
         $display("ERROR in sending data from UUT to mouse, %t, i = %d", $time, i);
         $finish;
      end
      else begin
         $display("ERROR TIMEOUT WAITING FOR MOUSE TO SEND DATA TO UUT, %t", $time);
         $finish;
      end
      
     end
     
      // SENDING 2ND PACKET OF 3 WORDS 
     //sending a 3 word movement packet
    for (i = 0; i <= 3; i = i + 1) begin
        if ( i == 0)
            data = packet.first_word;//valid packet class
        else if ( i == 1)
            data = {packet.stop1, packet.P1, packet.X_speed, packet.start1};
        else
            data = {packet.stop2, packet.P2, packet.Y_speed, packet.start2};
        
        fork
            mouse.send_packet(data);
        join_none//to move on to the next fork (wait for receipt, error or delay) after calling task  
        
        #42; //delay to wait for rx_available to go down
        //wait for receipt, error, or timeout
        fork
            wait(big_ps2_tb.UUT.ps2.err);
        
            wait(big_ps2_tb.UUT.ps2.data_available);
         
            wait_for_20_PS2_cycles();
        join_any
        disable fork;   
     end
               
    end             // initial end
     
    // Connect testbench with PS2 data and clock, as well as mouse 
    always @(posedge clk_25MHz or negedge clk_25MHz) begin
        if(mouse.mouse_sending| mouse.mouse_sending_ack_bit) begin
            PS2_data_drive = mouse.PS2_data_out; 
            PS2_clk_drive = mouse.PS2_clk_out;
        end
        else if (mouse.mouse_receiving) begin
            PS2_clk_drive = mouse.PS2_clk_out;
            mouse.PS2_data_in = PS2_data;
        end
        else begin
            PS2_clk_drive = mouse.PS2_clk_out;
            mouse.PS2_data_in = PS2_data;
            mouse.PS2_clk_in = PS2_clk;
        end
    end    
    
    always #20 clk_25MHz = ~clk_25MHz;
    
    always @ (posedge clk_25MHz) begin
        compare.compare_y_dir(packet.first_word[6], UUT.y_dir);
        compare.compare_y_speed(packet.Y_speed, UUT.y_speed);
        compare.compare_y_max_speed(packet.first_word[8], UUT.y_max_speed);
    end


endmodule
