`timescale 1ps / 1ps
`define CTMEM dut.\ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .mem

module tb_syn_task5();

    logic        CLOCK_50 = 0;
    logic [1:0]  KEY;
    logic [9:0]  SW, LEDR;
    logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    int errors = 0;

    task5 dut(.CLOCK_50(CLOCK_50), .KEY(KEY), .SW(SW),
              .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
              .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5), .LEDR(LEDR));

    always #5 CLOCK_50 = ~CLOCK_50;

    initial begin
	 
        KEY = 2'b01;                 // KEY[1]=0: reset asserted
		  
		  #10;
        $readmemh("test2.memh", `CTMEM);
        #20 
		  KEY = 2'b11;             // release
		  
        wait (dut.HEX0 !== 7'h7F);
		  repeat (5) @(posedge CLOCK_50);
		  
		  $display("HEX5..HEX0 = %h %h %h %h %h %h",
        dut.HEX5, dut.HEX4, dut.HEX3, dut.HEX2, dut.HEX1, dut.HEX0);
		  
        $stop;

    end

endmodule: tb_syn_task5
