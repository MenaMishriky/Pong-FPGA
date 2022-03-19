// This module is responsible for displaying the score on the 7-seg LED display
// Player is score_A and AI is score_B, on the display it will look like A - - B
// TODO: Create the 7-seg LED display driver

module scorer(clk_100MHz, reset, score_A, score_B, seg);
    input clk_100MHz;
    input reset;
    input score_A, score_B;
    output reg [7:0] seg;

    reg [3:0] score;
    reg [3:0] enables;
    reg [3:0] score_A_int, score_B_int;

    // Create signals in always block that cycles the anodes
    always @ (posedge clk_100MHz) begin
      if (reset)
        enables <= 4'b1110;                   // AN0
      else if (enables == 4'b1110)
        enables <= 4'b1101;                   // AN1
      else if (enables == 4'b1101)
        enables <= 4'b1011;                   // AN2
      else if (enables == 4'b1011)
        enables <= 4'b0111;                   // AN3
      else
        enables <= 4'b1110;
    end

    // Counters
    always @ (posedge score_A or posedge score_B or posedge reset) begin
      if (reset)  begin
        score_A <= 0;
        score_B <= 0;
      end
      else if (score_A)
        score_A_int <= score_A_int + 1;
      else
        score_B_int <= score_B_int + 1;
    end

    // Based on which enable is on, display the correct score give score_A or score_B or 10
    // to the reg score for case switching
    // if AN0 is on, display score_B
    // if AN3 is on, display score_A
    // if AN1 or AN2 are on, display '-'
    // SIM: Give clk, score_A, score_B, trigger for some amount of time
    always @ (enables or score_A or score_B) begin
      case (enables)
        4'b1110 : score = score_B;
        4'b0111 : score = score_A;
        default : score = 4'b1010;
      endcase
    end

    // 7 seg decoder for score, cathode patterns
    always @* begin
      case(score)
          4'h0: seg = 8'b00000011;             // A -> G, followed by DP
          4'h1: seg = 8'b10011111;
          4'h2: seg = 8'b00100101;
          4'h3: seg = 8'b00001101;
          4'h4: seg = 8'b10011001;
          4'h5: seg = 8'b01001001;
          4'h6: seg = 8'b01000001;
          4'h7: seg = 8'b00011111;
          4'h8: seg = 8'b00000001;
          4'h9: seg = 8'b00001001;
          default: seg = 8'b11111101;         // default : '-' unless given a #
      endcase
    end
endmodule