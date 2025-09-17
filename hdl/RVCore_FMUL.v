module RVCore_FMUL (
    input         clk,
    input         rstn,
    output        halted,
    output [31:0] imem_addr,
    input  [31:0] imem_rdata,
    output        dmem_we,
    output [31:0] dmem_addr,
    output [31:0] dmem_wdata,
    input  [31:0] dmem_rdata
);
    reg [63:0] pc;
    reg halt_r;
    assign halted   = halt_r;
    assign imem_addr = pc[31:0];

    reg [63:0] xreg [0:31];
    reg [31:0] freg [0:31];
    reg [63:0] addr_calc; 

    reg [1:0] state;
    localparam S_RUN=2'd0, S_LD1=2'd1, S_LD2=2'd2;
    reg [4:0]  ld_rd_f;     // čuvamo destinaciju za FLW
    reg [63:0] eff_addr;    // pomoćna adresa

    // Decode
    wire [31:0] instr = imem_rdata;
    wire [6:0]  opcode = instr[6:0];
    wire [2:0]  funct3 = instr[14:12];
    wire [6:0]  funct7 = instr[31:25];
    wire [4:0]  rd  = instr[11:7];
    wire [4:0]  rs1 = instr[19:15];
    wire [4:0]  rs2 = instr[24:20];
    wire [4:0]  rd_f  = rd;
    wire [4:0]  rs1_f = rs1;
    wire [4:0]  rs2_f = rs2;

    wire [63:0] imm_i = {{52{instr[31]}}, instr[31:20]};
    wire [63:0] imm_u = {{32{instr[31]}}, instr[31:12], 12'b0};
    wire [63:0] imm_s = {{52{instr[31]}}, instr[31:25], instr[11:7]};

    reg dmem_we_r;
    reg [31:0] dmem_addr_r;
    reg [31:0] dmem_wdata_r;
    assign dmem_we    = dmem_we_r;
    assign dmem_addr  = dmem_addr_r;
    assign dmem_wdata = dmem_wdata_r;

    wire op_is_fmul = (opcode==7'h53) && (funct7==7'h08);
    wire [31:0] fmul_A = op_is_fmul ? freg[rs1_f] : 32'h0000_0000;
    wire [31:0] fmul_B = op_is_fmul ? freg[rs2_f] : 32'h0000_0000;
    wire [31:0] fmul_out;
    FPMul_unit u_fmul(.A(fmul_A), .B(fmul_B), .P(fmul_out));

    integer i;
    // synthesis translate_off
    initial i = 0;
    // synthesis translate_on
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc <= 64'h0;
            halt_r <= 1'b0;
            dmem_we_r <= 1'b0;
            dmem_addr_r <= 32'd0;
            dmem_wdata_r <= 32'd0;
            state <= S_RUN;
            ld_rd_f <= 5'd0;
            eff_addr <= 64'd0;
            addr_calc <= 64'd0;
            // Initialize register files to known values to avoid X propagation
            for (i = 0; i < 32; i = i + 1) begin
                xreg[i] <= 64'd0;
                freg[i] <= 32'd0;
            end
        end else if (!halt_r) begin
            dmem_we_r <= 1'b0;            // default
            case (state)
        S_RUN: begin
            case (opcode)
            7'h37: begin // LUI
                xreg[rd] <= imm_u;
                pc <= pc + 64'd4;
            end

            7'h13: begin // OP-IMM (ADDI)
                if (funct3==3'b000) xreg[rd] <= xreg[rs1] + imm_i;
                pc <= pc + 64'd4;
            end

            7'h07: begin // LOAD-FP (FLW) — 2 cycles
            if (funct3==3'b010) begin
                addr_calc     = xreg[rs1] + imm_i;   
                eff_addr     <= addr_calc;           
                dmem_addr_r  <= addr_calc[31:0];     
                ld_rd_f      <= rd_f;                
                state        <= S_LD2;               
                end else begin
                    pc <= pc + 64'd4;
                end
            end

            7'h27: begin // STORE-FP (FSW)
            if (funct3==3'b010) begin
                addr_calc     = xreg[rs1] + imm_s;  
                dmem_addr_r  <= addr_calc[31:0];    
                dmem_wdata_r <= freg[rs2_f];
                dmem_we_r    <= 1'b1;
                end
                pc <= pc + 64'd4;
            end

            7'h53: begin // OP-FP (FMUL.S)
                if (funct7==7'h08) begin
                freg[rd_f] <= fmul_out;                 
                end
                pc <= pc + 64'd4;
            end

            7'h73: begin // SYSTEM (EBREAK)
                if (instr == 32'h0010_0073) halt_r <= 1'b1;
                pc <= pc + 64'd4;
            end

            default: pc <= pc + 64'd4; // NOP
            endcase
        end

        S_LD2: begin
            freg[ld_rd_f] <= dmem_rdata;
            state         <= S_RUN;
            pc            <= pc + 64'd4;
        end

        endcase

        xreg[0] <= 64'd0; // x0 = 0
        end
    end
endmodule
