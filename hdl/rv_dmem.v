module rv_dmem #(parameter WORDS=1024, parameter BASE=32'h0000_1000) (
    input         clk,
    input         we,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata
);
    reg [31:0] mem [0:WORDS-1];
    integer i;
    // synthesis translate_off
    initial i = 0;
    // synthesis translate_on
    initial begin
        for (i=0;i<WORDS;i=i+1) mem[i] = 32'h0;
        mem[(32'h0000_1000-BASE)>>2] = 32'h4000_0000; // 2.0
        mem[(32'h0000_1004-BASE)>>2] = 32'h4040_0000; // 3.0
        mem[(32'h0000_1008-BASE)>>2] = 32'h0000_0000; // 0.0
    end

    wire [31:0] idx_b = addr - BASE;
    wire [31:0] widx = idx_b >> 2;
    wire [31:0] ridx = idx_b >> 2;

    assign rdata = mem[ridx[ ($clog2(WORDS)-1) : 0 ]];

    always @(posedge clk) begin
        if (we) begin
            mem[widx[ ($clog2(WORDS)-1) : 0 ]] <= wdata;
        end
    end
endmodule
