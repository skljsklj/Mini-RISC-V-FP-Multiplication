module FP_Mul(
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] P
);
    wire sA = A[31]; wire [7:0] eA = A[30:23]; wire [22:0] fA = A[22:0];
    wire sB = B[31]; wire [7:0] eB = B[30:23]; wire [22:0] fB = B[22:0];

    wire sP = sA ^ sB;

    wire a_is_zero = (eA==8'd0) && (fA==23'd0);
    wire b_is_zero = (eB==8'd0) && (fB==23'd0);
    wire a_is_inf  = (eA==8'hff) && (fA==23'd0);
    wire b_is_inf  = (eB==8'hff) && (fB==23'd0);
    wire a_is_nan  = (eA==8'hff) && (fA!=23'd0);
    wire b_is_nan  = (eB==8'hff) && (fB!=23'd0);

    wire special_nan  = a_is_nan | b_is_nan | ((a_is_inf & b_is_zero) | (b_is_inf & a_is_zero));
    wire special_inf  = (a_is_inf & ~b_is_zero & ~b_is_nan) | (b_is_inf & ~a_is_zero & ~a_is_nan);
    wire special_zero = (a_is_zero | b_is_zero) & ~(a_is_inf | b_is_inf);

    wire [23:0] mA = (eA==8'd0) ? {1'b0, fA} : {1'b1, fA};
    wire [23:0] mB = (eB==8'd0) ? {1'b0, fB} : {1'b1, fB};

    wire [47:0] mP;
    Mant_Mult u_mult(.A(mA), .B(mB), .P(mP));

    wire [9:0] eA_eff = (eA==8'd0) ? 10'd1 : {2'b00,eA};
    wire [9:0] eB_eff = (eB==8'd0) ? 10'd1 : {2'b00,eB};
    wire [10:0] e_sum = eA_eff + eB_eff - 11'd127;

    wire [31:0] packed;
    MultNorm u_norm(.sign(sP), .exp_sum(e_sum[9:0]), .mant_prod(mP), .P(packed));

    reg [31:0] out;
    always @* begin
        if (special_nan)  out = {sP, 8'hff, 1'b1, 22'd0};
        else if (special_inf)  out = {sP, 8'hff, 23'd0};
        else if (special_zero) out = {sP, 8'd0,  23'd0};
        else out = packed;
    end
    assign P = out;
endmodule
