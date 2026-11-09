module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);
	 
	 logic [7:0] pt_addr, pt_data, pt_q;
	 logic pt_wren;
	 
	 logic [7:0] ct_addr2, ct_data2, ct_q2;
	 logic ct_wren2;
	 
	 logic [7:0] pt_addr1, pt_addr2, pt_data1, pt_data2, ct_address, ct_address2;
	 logic en1, en2, rdy1, rdy2, stop1, stop2, key_valid1, key_valid2, win;
	 logic [23:0] key1, key2;
	 
	 logic [7:0] len, n;
    
    pt_mem pt(.address(pt_addr), .clock(clk), .data(pt_data), .wren(pt_wren), .q(pt_q));
	 ct_mem ct2(.address(ct_addr2), .clock(clk), .data(ct_data2), .wren(ct_wren2), .q(ct_q2));

    crack c1(.clk(clk), .rst_n(rst_n), .en(en1), .rdy(rdy1), .start_index(0), .stop(stop1), .key(key1), .key_valid(key_valid1),
             .ct_addr(ct_address), .ct_rddata(ct_rddata), .pt_addr(pt_addr1), .pt_rddata(pt_data1));
				 
    crack c2(.clk(clk), .rst_n(rst_n), .en(en2), .rdy(rdy2), .start_index(1), .stop(stop2), .key(key2), .key_valid(key_valid2),
             .ct_addr(ct_address2), .ct_rddata(ct_q2), .pt_addr(pt_addr2), .pt_rddata(pt_data2));
				 
				 
				 
	 typedef enum logic [3:0]{
        IDLE, L_ADDR, L_READ, CT_ADDR, CT_WRITE, CRACK_START, CRACK_WAIT, CRACK_DONE, COPY, WRITE
    }states;	

	 states state, next_state;
	 
	 
	 
	 always_ff @(posedge clk or negedge rst_n) begin
	 
	     if (!rst_n) begin 
		      state     <= IDLE;
				len       <= 0;
				win       <= 0;
				key_valid <= 0;
				n         <= 0;
	     end else begin
		      state <= next_state;
		      
				if (state == IDLE && en) begin
				
				    n <= 0;
					 key_valid <= 0;
				
		      end else if (state == L_READ) len <= ct_rddata; //should be at address 0 cause this is before the crack modules begin?
				else if (state == CT_WRITE && n != len) n <= n + 1;
				else if (state == CRACK_WAIT) begin 
				
				    win <= key_valid1;
					 key_valid <= key_valid1 || key_valid2;
					 
				end else if (state == CRACK_DONE) n <= 0;
				else if (state == WRITE && n != len) n <= n + 1;

		  end
		  
	 end
				 
				 
	 always_comb begin
		  
	     next_state = state;
		  
        case (state)
            IDLE:  if (en) next_state = L_ADDR;
				L_ADDR: next_state = L_READ;
				L_READ: next_state = CT_ADDR;
				CT_ADDR: next_state = CT_WRITE;
				CT_WRITE: if (n == len) next_state = CRACK_START;
				          else next_state = CT_ADDR;
							 
				CRACK_START: if (rdy1 && rdy2) next_state = CRACK_WAIT;
				CRACK_WAIT:  if ((key_valid1 || key_valid2) || (rdy1 && rdy2)) next_state = CRACK_DONE;
				CRACK_DONE: next_state = COPY;
				COPY: next_state = WRITE;
				WRITE: if (n == len) next_state = IDLE;
				          else next_state = COPY;
        endcase	
		  
    end		 
    
	 assign en1 = (state == CRACK_START) && rdy1;
	 assign en2 = (state == CRACK_START) && rdy2;
	 
	 assign stop2 = (state == CRACK_DONE) &&  win;
    assign stop1 = (state == CRACK_DONE) && !win;
	 
	 assign ct_wren2 = (state == CT_WRITE);
	 assign ct_data2 = ct_rddata;
	 assign ct_addr  = (state == L_ADDR || state == L_READ || state == CT_ADDR || state == CT_WRITE) ? n : ct_address;
	 assign ct_addr2 = (state == L_ADDR || state == L_READ || state == CT_ADDR || state == CT_WRITE) ? n : ct_address2;
	 
	 assign pt_wren = (state == WRITE);
	 assign pt_addr = n;
	 assign pt_addr1 = n;
	 assign pt_addr2 = n;
	 
    assign key = win ? key1 : key2;
	 assign pt_data = win ? pt_data1 : pt_data2;
	 assign rdy = (state == IDLE) && rdy1 && rdy2;
	 
endmodule: doublecrack
