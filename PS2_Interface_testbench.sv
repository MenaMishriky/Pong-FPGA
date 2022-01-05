`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/21/2021 10:29:46 PM
// Design Name: 
// Module Name: sim_top
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

//packet class to be driven by driver
class packet_class; //33bit packet for the PS2 interface

    bit [10:0] first_word;//start0, LMB, RMB, zero, one, XS, YS, XY, YY,P0, stop0 MSB first!!!
    bit start1, stop1,P1;
    bit [7:0] X_speed;
    bit start2, stop2, P2;
    bit [7:0] Y_speed;
    bit valid;
    
    function new (bit randoms, bit [10:0] first_word,bit start1,bit [7:0] X_speed, bit P1, bit stop1, bit start2, bit [7:0] Y_speed, bit P2, bit stop2);
        if (!randoms) begin//if we want a user customized packet
            this.first_word = first_word;
            this.start1 = start1;
            this.X_speed = X_speed;
            this.P1 = P1;
            this.stop1 = stop1;
            this.start2 = start2;
            this.Y_speed = Y_speed;
            this.P2 = P2;
            this.stop2 = stop2;
            valid = (!start1 && stop1 && !start2 && stop2 && first_word[0] && !first_word[10] && !first_word[7] && first_word[6])? 1'b1 : 1'b0;
        end
        else begin //random but VALID packet (starts = 0, stops = 1, and first_word[3,4] = 2'b01
            bit [6:0] random_bits = $urandom_range(128);
            this.first_word = {1'b0, random_bits[1:0],2'b01, random_bits[6:2], 1'b1};
            this.start1 = 1'b0;
            this.X_speed = $urandom_range(0,256) ;
            this.P1 = $urandom_range(0,1);
            this.stop1 = 1'b1;
            this.start2 = 1'b0;
            this.Y_speed =$urandom_range(0,256) ;
            this.P2 = $urandom_range(0,1);
            this.stop2 = 1'b1;
            this.valid = 1'b1;
        end
    endfunction
    
endclass

//Driver class
class driver_class #(int packets = 1, int delay = 0);//packets = number of packets to send, delay is between packets (continuous vs burst)
  logic PS2_clk;
  logic PS2_data;
  packet_class good_data[]; //good is just a MISNOMER*****
  int first_word_count; //where are we in the first word (what bit)
  bit first_word_done, second_word_done, third_word_done;
  int second_word_count, third_word_count;
  int packet_counter;//which packet we are in right now
  bit [32:0] buffer;//used to put the data generated into a buffer (which is then used by the checker)
  
  function new ();
        this.PS2_clk = 1'b1;
        this.PS2_data = 1'b1;
  endfunction
  
 //The following task drives [packets] valid 33 bit packet to the design, either random or user defined, depending on the randoms bit, either continuous or delay
  task run(bit randoms, bit[10:0] first_word, bit start1, bit[7:0] X_speed, bit P1, bit stop1, bit start2,bit [7:0] Y_speed, P2, stop2);
      //initializing the counters and dones to 0
       first_word_count = 0;
       second_word_count = 0;
       third_word_count = 0;
     
       first_word_done = 0;
       second_word_done = 0;
       third_word_done = 0;
       
       PS2_clk = 1'b1;
       PS2_data = 1'b1;
       
       packet_counter = 0;
       
       //create and initialize packets
       this.good_data = new[packets];
        for (int i = 0; i < packets; i++) begin
              good_data[i] = new(randoms, first_word, start1, X_speed,P1,stop1,start2,Y_speed,P2,stop2);//user defined data
              buffer = {good_data[i].first_word, good_data[i].start1, good_data[i].X_speed, good_data[i].P1, good_data[i].stop1, good_data[i].start2, good_data[i].Y_speed, good_data[i].P2, good_data[i].stop2};
              $display("INSIDE CLASS, BUFFER %d is %x", i, buffer);  
              sim_top.input_buffer.push_back(buffer);     
        end
       
       fork //toggle clock while driving data
          
           forever #50000 PS2_clk = ~PS2_clk;//toggle clock
          
          
           forever @(posedge this.PS2_clk) begin //drive the data
               if(!first_word_done) begin //if we are still in the first word
                   PS2_data = good_data[packet_counter].first_word[10 - first_word_count]; //we wanna put the MSB first
                   first_word_count = first_word_count + 1;
                   if (first_word_count == 11) begin //end first word
                       first_word_count = 0;
                       first_word_done = 1'b1;
                   end
               end
               else if (!second_word_done) begin //if we re in the second word
                   if (second_word_count == 0) begin
                       second_word_count++;
                       PS2_data = good_data[packet_counter].start1; //start bit
                   end
                   else if ( second_word_count == 9) begin
                       PS2_data = good_data[packet_counter].P1; //parity
                       second_word_count ++;
                   end
                   else if ( second_word_count ==10) begin
                       PS2_data = good_data[packet_counter].stop1; //stop bit word 2
                       second_word_count ++;
                       second_word_count = 0;
                       second_word_done = 1;
                   end
                   else begin
                       PS2_data = good_data[packet_counter].X_speed[7- (second_word_count - 1)];
                       second_word_count ++;
                   end
               end
               else if (!third_word_done) begin // 3'rd 11-bit word in the 33bit packet
                   if (third_word_count == 0) begin
                        third_word_count++;
                        PS2_data = good_data[packet_counter].start2;
                   end
                   else if ( third_word_count == 9) begin
                        PS2_data = good_data[packet_counter].P2;
                        third_word_count ++;
                   end
                   else if ( third_word_count ==10) begin
                        PS2_data = good_data[packet_counter].stop2;
                        third_word_count ++;
                        third_word_count = 0;
                        third_word_done = 1;
                        
                        //if all three words of one packet are done, reset all counters and increment packet_counter
                        first_word_count = 0;
                        second_word_count = 0;
                        third_word_count = 0;
                              
                        first_word_done = 0;
                        second_word_done = 0;
                        third_word_done = 0;
                        packet_counter ++;
                        #delay; //normally 0 for continuous data. for  burst, give this a value close to 2000us which is 2000000ns
                        if (packet_counter == packets)  break;//if we drove all packets, exit 
                   end
                   else begin
                        PS2_data = good_data[packet_counter].Y_speed[7 - (third_word_count - 1)];
                        third_word_count ++;
                   end
               end//third word
          end//forever
      join_none;//wait/hang for both to finish
 endtask 
endclass

//Top and Testbench
//Terminology: one 33bit PACKET has 3 words, each word has 11 bits
module sim_top();
   //inputs
   reg PS2_clk_t;
   reg PS2_data_t;
   //outputs
   reg paddle0_direction_out;
   reg [7:0] paddle0_speed_out;
   reg invalid_out;
   
   //for the checker
   bit [32:0] input_buffer [$];//input from the driver
   int checker_counter;
   
   //delay is between packets (in ns, give 5000000 for burst mode, 0 for continuous), packets = num of packets to drive
   //in continuous mode, what happens is we get stop - 1cycle- start.....stop - 1 cycle -start
   driver_class #(.packets(3), .delay(0)) DRIVER  = new();
   
   
   /*
       DUT INSTANTIATION AND CONNECT TO I/O
   */
   
    
       
  initial begin
             //Pass the bits in the order you want to see them, so its randoms, start, LMB,.......,stop
             //first argument determines if you want to randmoize
             //if you want multiple packets, you can either choose random or have all the packets to be the same, which you customize through the args
             //if you pick random, provide garbage, placeholder args
             DRIVER.run(1,11'b00001010001, 0, 8'b00011011,0,1'b1,0, 8'b01010101,0,1'b1);
             checker_counter = 0;
             //ensure data is in the input buffer
             $display("INPUT DATA 0 IS %x\n", input_buffer[0]);
             $display("INPUT DATA 1 IS %x\n", input_buffer[1]);
             $display("INPUT DATA 2 IS %x\n", input_buffer[2]);
  end

//when packet is sent from driver to PS2, check the PS2 output (MONITOR)
  always @(DRIVER.packet_counter) begin 
        $display("PACKET_SENT\n");
        $display("COMPARING PACKET...\n");
        
        //should we have a delay?
        
        if (paddle0_direction_out == input_buffer[checker_counter][26]) begin//correct direction
            if ( (input_buffer[checker_counter][24] && (paddle0_speed_out == 8'hff)) || (!input_buffer[checker_counter][24] && (paddle0_speed_out == {input_buffer[checker_counter][2],input_buffer[checker_counter][3],input_buffer[checker_counter][4],input_buffer[checker_counter][5],input_buffer[checker_counter][6],input_buffer[checker_counter][7],input_buffer[checker_counter][8],input_buffer[checker_counter][9]})) ) begin//correct speed/overflow
                if(invalid_out == !DRIVER.good_data[0].valid) begin
                    $display("PACKET SUCCESSFULLY COMPARED!\n");
                end
                else begin
                    $display("FAILED: PACKET VALIDITY NOT CORRECTLY COMPARED! EXPECTED %s, GOT %s",DRIVER.good_data[0].valid, invalid_out);
                end
            end 
            else begin
                if(input_buffer[checker_counter][24]) $display("FAILED: SPEED OVERFLOW NOT HANDLED PROPERLY\n");
                else $display("FAILED: INCORRECT SPEED. EXPECTED %d, GOT %d\n", {input_buffer[checker_counter][2],input_buffer[checker_counter][3],input_buffer[checker_counter][4],input_buffer[checker_counter][5],input_buffer[checker_counter][6],input_buffer[checker_counter][7],input_buffer[checker_counter][8],input_buffer[checker_counter][9]}, paddle0_speed_out);
            end
        end
        else begin
            $display("FAILED: INCORRECT DIRECTION\n");
        end
  end
     
  always @(posedge DRIVER.PS2_clk or negedge DRIVER.PS2_clk) begin//Pass clock and data from driver to the registers (these then go to the design)
          PS2_clk_t = DRIVER.PS2_clk;
          PS2_data_t = DRIVER.PS2_data;
  end
   
endmodule
