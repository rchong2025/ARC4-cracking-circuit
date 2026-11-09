module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    logic [7:0] address, data, q;
	 logic wren;
	 //memory logics
	 
	 logic [7:0] init_address, init_data;
	 logic init_en, init_rdy, init_wren;
	 //init logics
	 
	 logic [7:0] ksa_address, ksa_data;
	 logic ksa_en, ksa_rdy, ksa_wren;
	 //ksa logics
	 
	 logic [7:0] prga_address, prga_data;
	 logic prga_en, prga_rdy, prga_wren;
	 //prga logics 
	 
	 
	 s_mem s(.address(address), .clock(clk), .data(data), .wren(wren), .q(q));
    
	 init i(.clk(clk), .rst_n(rst_n), .en(init_en), 
	        .rdy(init_rdy), .addr(init_address), .wrdata(init_data), .wren(init_wren));
			  
	 ksa k(.clk(clk), .rst_n(rst_n), .en(ksa_en), .rdy(ksa_rdy), .key(key), 
	       .addr(ksa_address), .rddata(q), .wrdata(ksa_data), .wren(ksa_wren));
				
    prga p(.clk(clk), .rst_n(rst_n), .en(prga_en), .rdy(prga_rdy), .key(key),
	        .s_addr(prga_address), .s_rddata(q), .s_wrdata(prga_data), .s_wren(prga_wren), .ct_addr(ct_addr), .ct_rddata(ct_rddata), 
           .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));
			  
	 //initalizations 
	 
	 
	 typedef enum logic [2:0]{
        IDLE, INIT_START, INIT, KSA_START, KSA, PRGA_START, PRGA
    }states;
	 
    states state, next_state;
	 //FSM states
	 
	 always_comb begin
	 case (state)
        INIT_START, INIT: begin
		      address = init_address;
				data    = init_data;
				wren    = init_wren;
		  end
		  KSA_START, KSA:   begin
		      address = ksa_address;
				data    = ksa_data;
				wren    = ksa_wren;
		  end
		  PRGA_START, PRGA: begin
		      address = prga_address;
				data    = prga_data;
				wren    = prga_wren;
		  end
		  default begin
		      address = 0;
				data    = 0;
				wren    = 0;
		  end
    endcase
	 end
	 //mux to determine which module gets access to S-RAM at a time
	 
	 always_ff @(posedge clk or negedge rst_n) if (!rst_n) state <= IDLE;
	     else state <= next_state;

	 always_comb begin
	 
	     next_state = state;
	 
	     case(state)
		  
		  IDLE:       if (en) next_state = INIT_START;
		  INIT_START: if (init_rdy) next_state = INIT;
		  INIT:       if (init_rdy) next_state = KSA_START; //for a one cycle delay, could also technically use a flag instead of another state 
		  KSA_START:  if (ksa_rdy)  next_state = KSA;
		  KSA:        if (ksa_rdy)  next_state = PRGA_START;
		  PRGA_START: if (prga_rdy) next_state = PRGA;
		  PRGA:       if (prga_rdy) next_state = IDLE;
		  
		  endcase
		  
    end
	 
	 assign init_en = (state == INIT_START) && init_rdy;
	 assign ksa_en = (state == KSA_START) && ksa_rdy;
	 assign prga_en = (state == PRGA_START) && prga_rdy;
	 assign rdy    = (state == IDLE);

endmodule: arc4
