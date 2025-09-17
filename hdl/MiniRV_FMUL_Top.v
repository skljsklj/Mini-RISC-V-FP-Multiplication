module MiniRV_FMUL_Top;
    reg clk=0;
    reg rstn=0;
    wire halted;

    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;

    wire        dmem_we;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;

    rv_imem #(.WORDS(64)) u_imem(.addr(imem_addr), .rdata(imem_rdata));
    rv_dmem #(.WORDS(1024), .BASE(32'h0000_1000)) u_dmem(
        .clk(clk), .we(dmem_we), .addr(dmem_addr), .wdata(dmem_wdata), .rdata(dmem_rdata)
    );

    RVCore_FMUL u_core(
        .clk(clk), .rstn(rstn), .halted(halted),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_we(dmem_we), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_rdata(dmem_rdata)
    );

    always #5 clk = ~clk;

    initial begin
        rstn = 0; #50; rstn = 1;
        wait(halted==1);
        #10;
        $display("DMEM[0x1008] = %h (expect 0x40C00000 for 6.0f)",
                 u_dmem.mem[(32'h0000_1008-32'h0000_1000)>>2]);
        #20; $finish;
    end
endmodule
