`timescale 1ns/1ps
module tb_minirv_fmul;
    // DUT instantiation (self-contained clock/reset inside)
    MiniRV_FMUL_Top dut();

    // Early visibility: print FMUL activity and DMEM writes
    initial begin
        $timeformat(-9, 3, " ns", 10);
        $display("TB started @ %0t", $realtime);
    end

    // Trace FMUL operands/results when the instruction is decoded
    always @(posedge dut.clk) begin
        if (dut.u_core.op_is_fmul) begin
            $display("%0t FMUL: A=%h B=%h -> P=%h", $time,
                     dut.u_core.fmul_A,
                     dut.u_core.fmul_B,
                     dut.u_core.fmul_out);
        end
        if (dut.dmem_we) begin
            $display("%0t DMEM[%h] <= %h", $time, dut.dmem_addr, dut.dmem_wdata);
        end
        if (dut.halted) begin
            $display("%0t HALTED; finishing.", $time);
            #20 $finish;
        end
    end

    // Safety timeout so sim doesn’t run forever if HALTED never asserts
    initial begin : timeout_guard
        // Adjust if your design runs longer; fallback stop after 10 us
        #10_000;
        $display("%0t TIMEOUT reached; forcing finish.", $time);
        $finish;
    end
endmodule
