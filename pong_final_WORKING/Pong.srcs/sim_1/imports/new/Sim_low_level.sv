/*`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/13/2022 10:24:50 PM
// Design Name: 
// Module Name: Sim_low_level
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

//packet class, constructs a random 33bit packet. The validity of the packet's parity depends on valid_x
class Packet_Class#(bit valid_x =1); //33bit packet for the PS2 interface

    bit [10:0] first_word;//MSB First, so Stop, parity, YY, XY YS, XS, 1, 0 R, L , Start
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

class mouse_class;
   bit mouse_sending, mouse_receiving, mouse_sending_ack_bit;
   logic PS2_data_in, PS2_data_out, PS2_clk_in, PS2_clk_out;//inputs and outputs to class, to be connected to DUT
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
     
     //when the DUT releases clock, mouse reads the first bit (the start bit)
     rx_counter = 'd1;
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
   
   
   //This task drives the DUT and sends it a packet (Mouse to PS2_interf)
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

class monitor_class;

    //task to compare two packets and returns if same or not
    task compare_packets (input [10:0] exp, input [10:0] received);      
      if(exp == received)
        $display("%t SUCCESS:Packet successfully compared", $time);
      else
        $display("%t : FAILED: incorrect packet. expected: %h, received: %h",$time, exp, received);    
    endtask
    
endclass

module Sim_low_level( );
  
  task wait_for_20_PS2_cycles;
     $display("%t entering wait task", $time);//debug
    #1250000;
    $display("%t leaving wait task", $time);//debug
  endtask
  
  reg clk_25MHz;
  wire PS2_clk;//since inout
  wire PS2_data;//since inout
  reg PS2_data_drive, PS2_clk_drive;
  reg reset;
  reg [10:0]tx_data;
  reg wr_en;
  wire [10:0] rx_data;
  wire data_available;
  wire busy;
  wire err;
  
  reg [10:0] data;//data to send from mouse to the DUT
  
  //instantiation of DUT, mouse and monitor
  mouse_class mouse = new();
  monitor_class monitor = new();
  Packet_Class packet = new();//create rand packet (valid)
  Packet_Class #(0) dutTxErrorPacket = new();//creat error packet for DUT to send to mouse
  Packet_Class #(0) dutRxErrorPacket = new();//creat error packet for DUT to receive from mouse
  PS2_interf_low_lvl DUT(PS2_clk, PS2_data, clk_25MHz, reset, tx_data, wr_en, rx_data, data_available, busy, err);
  
  //in real life,  if the interface writes to the clk, the mouse subits. interface is master
  assign PS2_clk = DUT.write_to_clk? 1'bz: (mouse.mouse_sending | mouse.mouse_receiving| mouse.mouse_sending_ack_bit)? PS2_clk_drive: 1'b1;//the last 1'b1 is the pullup resistor behavior
  assign PS2_data = DUT.write_to_data? 1'bz: (mouse.mouse_sending | mouse.mouse_receiving | mouse.mouse_sending_ack_bit)? PS2_data_drive: 1'b1;//the last 1'b1 is the pullup resistor behavior
  
  initial begin
      //mouse = new();
     // monitor = new();
     // packet = new();
      
      reset = 1'b0;
      clk_25MHz = 1'b1;
      tx_data = mouse.F4;
      wr_en = 1'b0;
      #1000;
      reset = 1'b1;
      #1000;
      reset = 1'b0;
      #1000;//stay idle for a bit
      
      //send F4 from DUT to mouse to enable data reporting
      $display("enabling wr_en, %t\n", $time);//DEBUG
      wr_en = 1'b1;
      #20;
      wr_en = 1'b0;
      $display("CALL MOUSE: RECEIVE_DATA, %t", $time);//DEBUG
      
      fork
        mouse.receive_data();
      join_none//to move on to the next fork (wait for receipt, error or delay) after calling task  
      
      //wait for mouse to receive F4 or timeout
      fork
                
          wait(mouse.rx_data_available);
          
          wait(err == 1'b1);
           
          wait_for_20_PS2_cycles();
         
      join_any
      disable fork;
      //compare what mouse received with F4. if correct, we now need to send movement data from mouse to DUT
      if(mouse.rx_data_available) begin
         monitor.compare_packets(mouse.F4, mouse.rx_data);
      end
      else if (err) begin
         $display("ERROR in sending data from DUT to mouse, %t", $time);
         $finish;
      end
      else begin
         $display("ERROR TIMEOUT WAITING FOR DUT TO SEND F4 TO MOUSE, %t", $time);
         $finish;
      end
      
      #100000;// change delay for burst/continuous data
      //send data from mouse to DUT
      
      //sending a 3 word movement packet
      for (int i = 0; i < 3; i = i + 1) begin
          if ( i == 0)
            data = packet.first_word;//valid packet class
          else if ( i == 1)
            data = {packet.stop1, packet.P1, packet.X_speed, packet.start1};
          else
            data = {packet.stop2, packet.P2, packet.Y_speed, packet.start2} ;
          
          fork
            mouse.send_packet(data);
         join_none//to move on to the next fork (wait for receipt, error or delay) after calling task  
         
          #42; //delay to wait for rx_available to go down
          //wait for receipt, error, or timeout
          fork
            wait(err);
            
            wait(data_available);
             
            wait_for_20_PS2_cycles();
         join_any
          
        //analyze result  
         if(err) begin
            $display("FAILED: DUT DETECTED ERROR IN CORRECT PACKET");
            $finish;
         end
         else if(data_available) begin
            monitor.compare_packets(data[10:0], rx_data);
         end
         else begin
            $display("FAILED: TIMEOUT WAITING FOR DUT TO RECEIVE DATA");
            $finish;
         end 
         disable fork;//so that we kill the wait task from previous iterations
     end//end for
     
     #41
     //now we test error packets
     
     //testing error flag when DUT receives incorrect packet
     fork
       mouse.send_packet(dutRxErrorPacket.first_word);
     join_none
     
     fork
       wait_for_20_PS2_cycles();
       
       wait(err);
       
       wait(data_available);
       
     join_any
  
     if (err) begin
        $display("Suceessfully detected error!");
     end
     else begin
        $display("FAILED: DUT failed to detect error in mouse data");
     end
     
     disable fork;
     #100000;
     mouse.rx_data_available = 1'b0;//ensure this is off before attemprting to transmit something else
     //now we try to send erroneous data to mouse to see if DUT raises error flag upon not getting ack
     tx_data = dutTxErrorPacket.first_word;
      $display("enabling wr_en to send erroneous data, %t\n", $time);//DEBUG
          wr_en = 1'b1;
          #20;
          wr_en = 1'b0;
          $display("CALL MOUSE: RECEIVE_DATA, %t", $time);//DEBUG
          
          fork
            mouse.receive_data();
          join_none//to move on to the next fork (wait for receipt, error or delay) after calling task  
          
          //wait for mouse to receive F4 or timeout
          fork
                    
              wait(mouse.rx_data_available);
              
              wait(err == 1'b1);
               
              wait_for_20_PS2_cycles();
             
          join_any
          disable fork;
          //compare what mouse received with F4. if correct, we now need to send movement data from mouse to DUT
          if(mouse.rx_data_available) begin
             $display("FAILED TO DETECT ABSNECE OF ACK FROM MOUSE");
          end
          else if (err) begin
             $display("Successfully detected mouse not giving ack bit! %t", $time);
             $finish;
          end
          else begin
             $display("ERROR TIMEOUT WAITING FOR DUT TO SEND ERROR FLAG, %t", $time);
             $finish;
          end
     
  end//end initial
  
  //connect testbench with PS2 data and clock, as well as mouse 
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
      PS2_clk_drive = mouse.PS2_clk_out;//MODIFICATION ADD THAT
      mouse.PS2_data_in = PS2_data;
      mouse.PS2_clk_in = PS2_clk;
    end
  end    
  
  
 //assertions (espectially important for TX FSM)
 always @(posedge clk_25MHz) begin
     if (mouse.delay100) begin 
        assert (PS2_data && !PS2_clk) else $display("%t FAILED ASSERTION: data or clk incorrect while delay100", $time);
     end//if delay100
     
     if (mouse.delay20) begin
      assert (!PS2_clk && !PS2_data) else $display("%t FAILED ASSERTION: data or clk incorrect while delay20",$time);
     end
 end
 
  always #20 clk_25MHz = ~clk_25MHz;//25MHZ clock generation
  
endmodule
*/