// Board I/O (DE10-Lite): CLOCK_50 is the 50 MHz clock and KEY[1] is the
// active-low reset (KEY[0] is unused). Keep these port names: the provided
// settings/DE10_Lite.qsf assigns them to the board's pins.
module task5(input logic CLOCK_50, input logic [1:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    logic [7:0] ct_address, ct_data = 0, ct_q;
	 logic ct_wren = 0;
	 //ct logics
	 
	logic [23:0] key;
   logic key_valid;
	 
	 logic en, rdy;
	 logic [1:0] flag;
	 //some flags

    ct_mem ct(.address(ct_address), .clock(CLOCK_50), .data(ct_data), .wren(ct_wren), .q(ct_q));

    doublecrack dc(.clk(CLOCK_50), .rst_n(KEY[1]), .en(en), .rdy(rdy), .key(key), .key_valid(key_valid),
             .ct_addr(ct_address), .ct_rddata(ct_q));
				 
				 
	 typedef enum logic [1:0]{
         CRACK_START, CRACK, DONE
    }states;	
    
    states state, next_state;	
	 //FSM states 
	 
	 always_comb 
        if (state != DONE)  flag = 2'd0;     
        else if (key_valid) flag = 2'd2;
        else                flag = 2'd1;

    always_ff @(posedge CLOCK_50 or negedge KEY[1]) begin
	 
	     if (!KEY[1]) state <= CRACK_START;
	     else state <= next_state;
		  
	 end
	 
	 always_comb begin
	 
	     next_state = state;
	 
	     case(state)
		  
		  CRACK_START: if (rdy) next_state = CRACK;
		  CRACK:       if (rdy) next_state = DONE;
		  DONE:        next_state = DONE;
		  
		  endcase
		  
    end
	 
	 assign en = (state == CRACK_START) && rdy;
	 
	 seg7 seg1(.in(key[3:0]),   .flag(flag), .seg7(HEX0));
	 seg7 seg2(.in(key[7:4]),   .flag(flag), .seg7(HEX1));
	 seg7 seg3(.in(key[11:8]),  .flag(flag), .seg7(HEX2));
	 seg7 seg4(.in(key[15:12]), .flag(flag), .seg7(HEX3));
	 seg7 seg5(.in(key[19:16]), .flag(flag), .seg7(HEX4));
	 seg7 seg6(.in(key[23:20]), .flag(flag), .seg7(HEX5));

endmodule: task5
