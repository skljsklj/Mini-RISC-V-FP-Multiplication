module MultNorm(
    input        sign,
    input  [9:0] exp_sum,
    input [47:0] mant_prod,
    output [31:0] P
);
    wire l2 = mant_prod[47];
    wire [23:0] mant_a = mant_prod[47:24];
    wire guard_a = mant_prod[23];
    wire round_a = mant_prod[22];
    wire sticky_a = |mant_prod[21:0];

    wire [23:0] mant_b = mant_prod[46:23];
    wire guard_b = mant_prod[22];
    wire round_b = mant_prod[21];
    wire sticky_b = |mant_prod[20:0];

    wire [23:0] mant_pre = l2 ? mant_a : mant_b;
    wire guard = l2 ? guard_a : guard_b;
    wire roundb = l2 ? round_a : round_b;
    wire sticky = l2 ? sticky_a : sticky_b;

    wire signed [11:0] e_bi_pre = $signed({2'b00,exp_sum}) + (l2 ? 12'sd1 : 12'sd0);

    wire lsb = mant_pre[0];
    wire round_up = (guard & (roundb | sticky)) | (guard & ~roundb & ~sticky & lsb);
    // Round with an extra bit to detect true overflow (1.xx -> 10.xx)
    wire [24:0] mant_ext = {1'b0, mant_pre} + (round_up ? 25'd1 : 25'd0);
    wire carry = mant_ext[24];
    wire [22:0] mant_f = carry ? mant_ext[23:1] : mant_ext[22:0];
    // If rounding overflows the mantissa, bump the biased exponent
    wire signed [11:0] e_bi2 = carry ? (e_bi_pre + 12'sd1) : e_bi_pre;

    wire signed [11:0] e_bi_s = e_bi2;
    wire [8:0] e_bi9 = (e_bi_s < 12'sd0) ? 9'd0 :
                       (e_bi_s > 12'sd255) ? 9'd511 : {1'b0, e_bi_s[7:0]};
    wire [7:0] e_bi = e_bi9[7:0];
    wire ovf = (e_bi9[8]==1'b1) || (e_bi==8'hff);
    wire unf = (e_bi==8'd0);

    reg [31:0] packed;
    always @* begin
        if (ovf) packed = {sign, 8'hff, 23'd0};
        else if (unf) packed = {sign, 8'd0, 23'd0};
        else packed = {sign, e_bi, mant_f};
    end
    assign P = packed;
endmodule
