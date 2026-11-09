module crack(input logic clk, input logic rst_n,
             input logic en, output logic rdy, input logic start_index, input logic stop,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
				 input logic [7:0] pt_addr, output logic [7:0] pt_rddata);

    logic [7:0] pt_address, pt_data, pt_q;
	 logic pt_wren;
	 //pt logics
	 
	 logic arc_en, arc_rdy;
	 logic [7:0] arc_addr;
	 
	 logic [23:0] i;
	 logic bad;
	 //counter and flags
	 
	 typedef enum logic [1:0] {IDLE, START, WAIT, CHECK} states;
    states state, next_state;
	 //FSM states
				
				
    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(.address(pt_address), .clock(clk), .data(pt_data), .wren(pt_wren), .q(pt_q));
	 
    arc4 a4(.clk(clk), .rst_n(rst_n), .en(arc_en), .rdy(arc_rdy), .key(key),
            .ct_addr(ct_addr), .ct_rddata(ct_rddata), .pt_addr(arc_addr), .pt_rddata(pt_q), .pt_wrdata(pt_data), .pt_wren(pt_wren));
	 //instantiations

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            i         <= 0;
				bad       <= 0;
				key_valid <= 0;
				
		  end else if (stop) begin
		      state     <= IDLE;
            i         <= 0;
				bad       <= 0;
				key_valid <= 0;
				
		  end else begin
		  
		      state <= next_state;
								
				if (state == START) bad <= 0;
            else if (pt_wren && arc_addr != 8'd0 && (pt_data < 8'h20 || pt_data > 8'h7E)) bad <= 1;
				
				if (state == IDLE && en) begin
                i <= start_index;
				    key_valid <= 0;
				end else if (state == CHECK && !bad) key_valid <= 1;
				else if (state == CHECK && i[23:1] != 23'h7FFFFF) i <= i + 2;
				
		  end
	 end
	 
	 always_comb begin
		  
	     next_state = state;
		  
        case (state)
            IDLE:  if (en) next_state = START;
				START: if (arc_rdy) next_state = WAIT;
				WAIT:  if (arc_rdy) next_state = CHECK;
				CHECK: if (i[23:1] == 23'h7FFFFF || !bad) next_state = IDLE;
				       else next_state = START;
        endcase	
		  
    end
	 
	 assign arc_en = (state == START) && arc_rdy;
	 assign rdy = (state == IDLE) && arc_rdy;
	 assign key = i;
	 assign pt_address = rdy ? pt_addr : arc_addr; //if ready, not currently calculating, pt can be read by double
	                                               //if not ready, currently calculating, pt can be read by arc4
	 assign pt_rddata = pt_q;
		  
endmodule: crack
