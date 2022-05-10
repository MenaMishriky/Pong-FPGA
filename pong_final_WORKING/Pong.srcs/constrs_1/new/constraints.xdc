## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]
 	
#7 segment display
set_property PACKAGE_PIN W7 [get_ports {segs[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {segs[7]}]
set_property PACKAGE_PIN W6 [get_ports {segs[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {segs[6]}]
set_property PACKAGE_PIN U8 [get_ports {segs[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {segs[5]}]
set_property PACKAGE_PIN V8 [get_ports {segs[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {segs[4]}]
set_property PACKAGE_PIN U5 [get_ports {segs[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {segs[3]}]
set_property PACKAGE_PIN V5 [get_ports {segs[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {segs[2]}]
set_property PACKAGE_PIN U7 [get_ports {segs[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {segs[1]}]
set_property PACKAGE_PIN V7 [get_ports segs[0]]							
	set_property IOSTANDARD LVCMOS33 [get_ports segs[0]]

set_property PACKAGE_PIN U2 [get_ports {enables[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {enables[0]}]
set_property PACKAGE_PIN U4 [get_ports {enables[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {enables[1]}]
set_property PACKAGE_PIN V4 [get_ports {enables[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {enables[2]}]
set_property PACKAGE_PIN W4 [get_ports {enables[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {enables[3]}]


##Buttons
set_property PACKAGE_PIN U18 [get_ports reset]						
	set_property IOSTANDARD LVCMOS33 [get_ports reset]
    set_property PULLDOWN true [get_ports reset]
    
##USB HID (PS/2)
set_property PACKAGE_PIN C17 [get_ports PS2_CLK]						
	set_property IOSTANDARD LVCMOS33 [get_ports PS2_CLK]
	set_property PULLUP true [get_ports PS2_CLK]
set_property PACKAGE_PIN B17 [get_ports PS2_DATA]					
	set_property IOSTANDARD LVCMOS33 [get_ports PS2_DATA]
	set_property PULLUP true [get_ports PS2_DATA]
	
##VGA Connector
set_property PACKAGE_PIN G19 [get_ports {red_VGA[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {red_VGA[0]}]
set_property PACKAGE_PIN H19 [get_ports {red_VGA[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {red_VGA[1]}]
set_property PACKAGE_PIN J19 [get_ports {red_VGA[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {red_VGA[2]}]
set_property PACKAGE_PIN N19 [get_ports {red_VGA[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {red_VGA[3]}]
set_property PACKAGE_PIN N18 [get_ports {blue_VGA[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {blue_VGA[0]}]
set_property PACKAGE_PIN L18 [get_ports {blue_VGA[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {blue_VGA[1]}]
set_property PACKAGE_PIN K18 [get_ports {blue_VGA[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {blue_VGA[2]}]
set_property PACKAGE_PIN J18 [get_ports {blue_VGA[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {blue_VGA[3]}]
set_property PACKAGE_PIN J17 [get_ports {green_VGA[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {green_VGA[0]}]
set_property PACKAGE_PIN H17 [get_ports {green_VGA[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {green_VGA[1]}]
set_property PACKAGE_PIN G17 [get_ports {green_VGA[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {green_VGA[2]}]
set_property PACKAGE_PIN D17 [get_ports {green_VGA[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {green_VGA[3]}]
set_property PACKAGE_PIN P19 [get_ports hsync_VGA]						
	set_property IOSTANDARD LVCMOS33 [get_ports hsync_VGA]
set_property PACKAGE_PIN R19 [get_ports vsync_VGA]						
	set_property IOSTANDARD LVCMOS33 [get_ports vsync_VGA]







# LEDs
set_property PACKAGE_PIN U16 [get_ports {LED_mouseCTL_RESET}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED_mouseCTL_RESET}]
set_property PACKAGE_PIN E19 [get_ports {LED_mouseCTL_WAIT_ACK}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED_mouseCTL_WAIT_ACK}]
set_property PACKAGE_PIN U19 [get_ports {LED_mouseCTL_IDLE_REPORTING}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED_mouseCTL_IDLE_REPORTING}]
set_property PACKAGE_PIN V19 [get_ports {LED_mouseCTL_INVALID_DATA}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED_mouseCTL_INVALID_DATA}]
set_property PACKAGE_PIN W18 [get_ports {LED_WORD3_triggered}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED_WORD3_triggered}]
#set_property PACKAGE_PIN U15 [get_ports {LED[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
#set_property PACKAGE_PIN U14 [get_ports {LED[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
#set_property PACKAGE_PIN V14 [get_ports {LED[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
#set_property PACKAGE_PIN V13 [get_ports {LED[8]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED[8]}]
#set_property PACKAGE_PIN V3 [get_ports {LED[9]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED[9]}]
#set_property PACKAGE_PIN W3 [get_ports {LED[10]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED[10]}]
#set_property PACKAGE_PIN U3 [get_ports {LED[11]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED[11]}]
set_property PACKAGE_PIN P3 [get_ports { LED_ID_received}]					
	set_property IOSTANDARD LVCMOS33 [get_ports { LED_ID_received}]
set_property PACKAGE_PIN N3 [get_ports {LED_data_available_triggered}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED_data_available_triggered}]
set_property PACKAGE_PIN P1 [get_ports {LED_TX_ERROR_triggered}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED_TX_ERROR_triggered}]
set_property PACKAGE_PIN L1 [get_ports {LED_RX_ERROR_triggered}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED_RX_ERROR_triggered}]
	
	
##USB-RS232 Interface
#set_property PACKAGE_PIN B18 [get_ports RsRx]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsRx]
#set_property PACKAGE_PIN A18 [get_ports RsTx]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsTx]

##Quad SPI Flash
##Note that CCLK_0 cannot be placed in 7 series devices. You can access it using the
##STARTUPE2 primitive.
#set_property PACKAGE_PIN D18 [get_ports {QspiDB[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[0]}]
#set_property PACKAGE_PIN D19 [get_ports {QspiDB[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[1]}]
#set_property PACKAGE_PIN G18 [get_ports {QspiDB[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[2]}]
#set_property PACKAGE_PIN F18 [get_ports {QspiDB[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[3]}]
#set_property PACKAGE_PIN K19 [get_ports QspiCSn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports QspiCSn]
