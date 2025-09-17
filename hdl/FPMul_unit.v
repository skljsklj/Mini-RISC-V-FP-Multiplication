module FPMul_unit(
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] P
);
    FP_Mul u(.A(A), .B(B), .P(P));
endmodule
