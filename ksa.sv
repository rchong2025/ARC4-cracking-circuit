module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);
			  
	/*
	j=0
   fori=0to255:
       j=(j+s[i]+key[imodkeylength])mod256--forus,keylengthis3
       swapvalues ofs[i]ands[j]
*/

    typedef enum logic [2:0] {IDLE, ADDR_I, ADDR_J, READ_I, READ_J, WRITE_I, WRITE_J} states;
    states state, next_state;
	 
    logic [7:0] i, j, data_i, data_j, k_data;
	 
	 logic [1:0] k;
	 assign k = i%3;
	 
	 always_comb begin
	     case (k)
		      00: k_data = key[23:16];
		      01: k_data = key[15:8];
		      default: k_data = key[7:0];
		  endcase
	 end
	 //for key data values

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            i     <= 0;
				j     <= 0;
				data_i <= 0;
				data_j <= 0;
				
		  end else begin
		  
		      state <= next_state;
		  
		      case (state) //updating intermediate signals
				    IDLE:    if (en) begin
                             i <= 0;
                             j <= 0;
                         end
				    READ_I: begin
						  data_i <= rddata;
						  j <= (j + rddata + k_data) % 256; //j needs to be updated here before state turns into address j
					 end
					 READ_J: data_j <= rddata;
				    WRITE_J: if (i != 255) i <= i + 1;
		  
		      endcase
		  end
	end	
    
	always_comb begin
		  
		      next_state = state;
		  
            case (state)
                IDLE:  if (en) next_state = ADDR_I;	  
                ADDR_I: next_state        = READ_I; //inbetween waiting state for address to update
					 READ_I: next_state        = ADDR_J;
					 ADDR_J: next_state        = READ_J; //inbetween waiting state for address to update
					 READ_J: next_state        = WRITE_I;
					 WRITE_I: next_state       = WRITE_J; //state to write i using the wr_data assignment 
					 WRITE_J: if (i == 255) next_state = IDLE;
						       else next_state = ADDR_I; 
            endcase
				
    end

    assign rdy    = (state == IDLE);
    assign wren   = (state == WRITE_I || state == WRITE_J);
    assign addr   = (state == ADDR_I || state == READ_I || state == WRITE_I) ? i : j;
    assign wrdata = (state == WRITE_I) ? data_j : data_i; //purposefully swapped so if writting i, writes data from j and etc. 

endmodule: ksa
