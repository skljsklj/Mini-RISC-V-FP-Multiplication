module rv_imem #(parameter WORDS=64) (
    input  [31:0] addr,
    output [31:0] rdata
);
    reg [31:0] mem [0:WORDS-1];
    integer i;
    // synthesis translate_off
    initial i = 0;
    // synthesis translate_on
    initial begin
        // default NOP
        for (i=0;i<WORDS;i=i+1) mem[i] = 32'h00000013;

        // 0: LUI  x1, 0x1          -> x1 = 0x00001000
        // 1: FLW  f1, 0(x1)        -> f1 = 2.0f @0x1000
        // 2: FLW  f2, 4(x1)        -> f2 = 3.0f @0x1004
        // 3: FMUL.S f3,f1,f2       -> f3 = 6.0f
        // 4: FSW  f3, 8(x1)        -> store @0x1008
        // 5: EBREAK
        mem[0] = 32'h001000B7; // LUI  x1,0x1
        mem[1] = 32'h0000A087; // FLW  f1,0(x1)
        mem[2] = 32'h0040A107; // FLW  f2,4(x1)
        mem[3] = 32'h102081D3; // FMUL.S f3,f1,f2
        mem[4] = 32'h0030A427; // FSW  f3,8(x1)
        mem[5] = 32'h00100073; // EBREAK
    end
    assign rdata = mem[addr[31:2]];
endmodule
