module scorer_tb();
    // inputs
    reg clk_100MHz_tb;
    reg reset_tb;
    reg score_A_tb;
    reg score_B_tb;
    // outputs
    wire [7:0] seg_tb;
    
    scorer UUT (.clk_100MHz(clk_100MHz_tb),
                .reset(reset_tb),
                .score_A(score_A_tb),
                .score_B(score_B_tb),
                .seg (seg_tb)
                );
    
    initial begin
        clk_100MHz_tb = 1'b0;
        reset_tb = 1'b0;
        score_A_tb = 1'b1;
        score_B_tb = 1'b1; 
        #2000
        reset_tb = 1'b1;
        #2000
        reset_tb = 1'b0;
    end
    
    always #10 clk_100MHz_tb = ~clk_100MHz_tb;
    always #500 score_A_tb = ~score_A_tb;
    always #500 score_B_tb = ~score_B_tb;
endmodule
