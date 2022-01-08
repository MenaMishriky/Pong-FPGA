LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY mouse_ps2_vhdl IS
  GENERIC(
      clk_freq                  : INTEGER := 100_000_000;       --system clock frequency in Hz
      ps2_debounce_counter_size : INTEGER := 8);                --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
      clk            : IN     STD_LOGIC;                        --system clock input
      reset_n        : IN     STD_LOGIC;                        --active low asynchronous reset
      ps2_clk        : IN     STD_LOGIC;                        --clock signal from PS2 mouse
      ps2_data       : IN     STD_LOGIC;                        --data signal from PS2 mouse
      mouse_data     : OUT    STD_LOGIC_VECTOR(32 DOWNTO 0);    --data received from mouse
      mouse_data_new : OUT    STD_LOGIC;                        --new data packet available flag
      error_flag     : OUT    STD_LOGIC;                        --error flag if packet is corrupted
      paddle_dir     : OUT    INTEGER;                          --data translated into y-direction
      paddle_speed   : OUT    INTEGER                           --data translated into y-speed
      );     
END mouse_ps2_vhdl;

ARCHITECTURE logic OF mouse_ps2_vhdl IS
  TYPE machine IS(reset, rx_ack1, rx_bat, rx_id, ena_reporting, rx_ack2, stream);  --needed states
  SIGNAL state             : machine := reset;              --state machine  
  SIGNAL tx_ena            : STD_LOGIC := '0';              --transmit enable for ps2_transceiver
  SIGNAL tx_cmd            : STD_LOGIC_VECTOR(8 DOWNTO 0);  --command to transmit
  SIGNAL tx_busy           : STD_LOGIC;                     --ps2_transceiver busy signal
  SIGNAL ps2_code          : STD_LOGIC_VECTOR(7 DOWNTO 0);  --PS/2 code received from ps2_transceiver
  SIGNAL ps2_code_new      : STD_LOGIC;                     --new PS/2 code available flag from ps2_transceiver
  SIGNAL ps2_code_new_prev : STD_LOGIC;                     --previous value of ps2_code_new
  SIGNAL packet_byte       : INTEGER RANGE 0 TO 2 := 2;     --counter to track which packet byte is being received
  SIGNAL mouse_data_int    : STD_LOGIC_VECTOR(32 DOWNTO 0); --internal mouse data register
  SIGNAL k                 : INTEGER;

  BEGIN 
  
  PROCESS(clk, reset_n)  
  BEGIN 
      IF(ps2_code_new_prev = '0' AND ps2_code_new = '1') THEN                     --new PS/2 code received
                mouse_data_new <= '0';                                                      --clear new data packet available flag
                mouse_data_int(7+packet_byte*8 DOWNTO packet_byte*8) <= ps2_code;           --store new mouse data byte
                IF(packet_byte = 0) THEN                                                    --all bytes in packet received and presented
                  packet_byte <= 2;                                                           --clear packet byte counter
                ELSE                                                                        --not all bytes in packet received yet
                  packet_byte <= packet_byte - 1;                                             --increment packet byte counter
                END IF;      
              
              IF(ps2_code_new_prev = '1' AND ps2_code_new = '1' AND packet_byte = 2) THEN --mouse data receive is complete
                mouse_data <= mouse_data_int;                                               --present new mouse data at output
                mouse_data_new <= '1';                                                      --set new data packet available flag
              END IF;
              
              IF(packet_byte = 2) THEN  
                paddle_speed <= to_integer(unsigned(mouse_data));
              END IF;
              IF(packet_byte = 0) THEN
                grab_dir: FOR i in 0 to mouse_data'length-1 LOOP 
                    paddle_dir <= to_integer(unsigned(mouse_data));
              END IF;
       END IF;
    END PROCESS;   
END logic;
