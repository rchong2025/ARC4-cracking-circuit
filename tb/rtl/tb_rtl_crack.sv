`timescale 1ps / 1ps
`define CTMEM ct.altsyncram_component.m_default.altsyncram_inst.mem_data
`define PTMEM dut.pt.altsyncram_component.m_default.altsyncram_inst.mem_data

module tb_rtl_crack();

    logic clk = 0, rst_n, en, rdy, start_index = 0, stop = 0;
	 
	 logic [23:0] key;
	 logic [7:0] ct_addr, ct_q, ct_data = 0;
	 logic [7:0] pt_addr = 0, pt_data;
	 logic key_valid, ct_wren = 0;

    crack dut(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), .start_index(start_index), .stop(stop), .key(key), 
	         .key_valid(key_valid), .ct_addr(ct_addr), .ct_rddata(ct_q), .pt_addr(pt_addr), .pt_rddata(pt_data));
				 
    ct_mem ct(.address(ct_addr), .clock(clk), .data(ct_data), .wren(ct_wren), .q(ct_q));
	 
	 always #5 clk = ~clk;
	 
	 initial begin
	 
            rst_n = 0; en = 0;
            #10;   // wait 
				$readmemh("test2.memh", `CTMEM);

            #20 
		      rst_n = 1;
		  
            @(posedge clk); #1; //wait for a posedge of clk
            wait (rdy);     //wait until ready is high
            en = 1; 
		  
		      @(posedge clk); #1;
		      en = 0;
		  
            @(posedge clk); #1; 
            wait (rdy);    //by here, init should be done
		      @(posedge clk); #1; //but just in case
		  
		        $display("key_valid = %b, key = %h", key_valid, key);
              $display("length = %0d", `PTMEM[0]);
              for (int y = 1; y <= `PTMEM[0]; y++) $write("%c", `PTMEM[y]);
              $display("");

         $stop;
		  
    end


endmodule: tb_rtl_crack
