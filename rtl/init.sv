module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

    typedef enum logic [0:0] {IDLE, WRITE} state_t;
    state_t state;
    logic [8:0] i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            i     <= 9'd0;
        end else begin
            case (state)
                IDLE:  if (en) begin
                           state <= WRITE;
                           i     <= 9'd0;
                       end
                WRITE: if (i == 9'd255) state <= IDLE;
                       else             i <= i + 9'd1;
            endcase
        end
    end

    assign rdy    = (state == IDLE);
    assign wren   = (state == WRITE);
    assign addr   = i[7:0];
    assign wrdata = i[7:0];

endmodule: init