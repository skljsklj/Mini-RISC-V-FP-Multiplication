module Mant_Mult(
    input  [23:0] A,
    input  [23:0] B,
    output [47:0] P
);
    assign P = A * B;
endmodule
