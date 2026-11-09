module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);
				
				/*
				i = 0, j = 0
            for k = 0 to message_length-1:
                i = (i+1) mod 256
                j = (j+s[i]) mod 256
                swap values of s[i] and s[j]
                pad[k] = s[(s[i]+s[j]) mod 256]
            for k = 0 to message_length-1:
                plaintext[k] = pad[k] xor ciphertext[k]-- xor each byte
					 
					 note:
					 ciphertext = ct_rddata
					 plaintext = pt_rddata
					 pad = intermediate signal I think?
				*/

				typedef enum logic [3:0] {IDLE, ADDR_L, READ_L, WRITE_L, ADDR_I, ADDR_J, READ_I, READ_J, WRITE_I, WRITE_J, ADDR_T, READ_T,
				                          WRITE_P} states;
            states state, next_state;
	 
            logic [7:0] i, j, k, len, data_i, data_j, out;
				
				always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    state  <= IDLE;
						  
                    i      <= 0;
				        j      <= 0;
						  k      <= 0;
						  
				        data_i <= 0;
				        data_j <= 0;
						  out    <= 0;
						  len    <= 0;
				
		           end else begin
		               state <= next_state;
							
							case (state) 
							    IDLE: if (en) begin
								     i <= 0;
									  j <= 0;
									  k <= 0;
								 end
							    READ_L: len <= ct_rddata;
								 WRITE_L: begin i <= i + 1; k <= k + 1; end //k starts at 1 cause 0 is for length
							    READ_I: begin
								     data_i <= s_rddata % 256;
									  j <= j + s_rddata % 256;
								 end
								 READ_J: data_j <= s_rddata;
								 READ_T: out <= s_rddata^ct_rddata;
								 WRITE_P: begin
								     if (k != len) begin
									      k <= k + 1;
											i <= i + 1;
									  end else k <= 0;
					          end
							endcase
						end
				end
				
				always_comb begin
		  
		          next_state = state;
		  
                case (state)
                    IDLE:  if (en) next_state = ADDR_L;
						  ADDR_L: next_state = READ_L;
						  READ_L: next_state = WRITE_L;
						  WRITE_L: if (len == 0) next_state = IDLE;
						           else next_state = ADDR_I; //getting length for loop
						  
					     ADDR_I: next_state = READ_I; //start of for loop
					     READ_I: next_state = ADDR_J;
					     ADDR_J: next_state = READ_J;
					     READ_J: next_state = WRITE_I;
						  WRITE_I: next_state = WRITE_J;
						  
						  WRITE_J: next_state = ADDR_T;
						  ADDR_T: next_state = READ_T;
						  READ_T: next_state = WRITE_P;
						  WRITE_P: if (k == len) next_state = IDLE;
						           else next_state = ADDR_I;
						  default: next_state = IDLE;
                endcase
				
            end

    assign rdy    = (state == IDLE);
	 assign s_wren   = (state == WRITE_I || state == WRITE_J);
	 assign s_wrdata = (state == WRITE_I) ? data_j : data_i; //purposefully swapped so if writting i, writes data from j and etc.
	 
	 always_comb begin
    case (state)
        ADDR_I, READ_I, WRITE_I: s_addr = i;
        ADDR_J, READ_J, WRITE_J: s_addr = j;
        ADDR_T, READ_T:          s_addr = data_i + data_j;   // 8-bit, wraps mod 256
        default:                 s_addr = i;
    endcase
    end
	 //assign for s_addr
    
	 assign ct_addr = k;
	 assign pt_addr = k;
	 assign pt_wren = (state == WRITE_L) || (state == WRITE_P);
	 assign pt_wrdata = (state == WRITE_L) ? len : out;

endmodule: prga
