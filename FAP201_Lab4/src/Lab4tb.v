`timescale 1ns/1ps

module lab04_tb;

    localparam CLK_PERIOD = 20;

    reg  clk      = 1'b0;
    reg  i_sw_raw = 1'b0;
    reg  i_rst    = 1'b0;
    wire o_led;
    wire o_dbg_stable;

    integer errors = 0;

    // Clock 50 MHz
    always #(CLK_PERIOD/2) clk = ~clk;

    // STABLE_CYCLES nhỏ (5) chỉ để mô phỏng nhanh
    lab04 #(.STABLE_CYCLES(5)) DUT (
        .clk(clk),
        .i_sw_raw(i_sw_raw),
        .i_rst(i_rst),
        .o_led(o_led),
        .o_dbg_stable(o_dbg_stable)
    );

    // Kiểm tra tự động
    task check;
        input cond;
        input [8*40-1:0] msg;
        begin
            if (!cond) begin
                $display("%0s", msg);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // T0. Reset
        i_rst = 1'b1;
        #(4*CLK_PERIOD);
        i_rst = 1'b0;
        #(3*CLK_PERIOD);
        check(o_led == 1'b0,        "T0 FAILED: LED must reset to 0");
        check(o_dbg_stable == 1'b0, "T0 FAILED: stable must reset to 0");

        // T1. Nhấn có nảy
        i_sw_raw = 1'b1; #(1*CLK_PERIOD);
        i_sw_raw = 1'b0; #(1*CLK_PERIOD);
        i_sw_raw = 1'b1; #(1*CLK_PERIOD);
        i_sw_raw = 1'b0; #(1*CLK_PERIOD);
        i_sw_raw = 1'b1;
        #(12*CLK_PERIOD);
        check(o_dbg_stable == 1'b1, "T1 FAILED: press not accepted");
        check(o_led == 1'b0,        "T1 FAILED: press toggled LED");

        // T2. Giữ nút lâu, không toggle thêm
        #(20*CLK_PERIOD);
        check(o_led == 1'b0, "T2 FAILED: LED changed while pressed");

        // T3. Nhả có nảy
        i_sw_raw = 1'b0; #(1*CLK_PERIOD);
        i_sw_raw = 1'b1; #(1*CLK_PERIOD);
        i_sw_raw = 1'b0; #(1*CLK_PERIOD);
        i_sw_raw = 1'b1; #(1*CLK_PERIOD);
        i_sw_raw = 1'b0;
        #(16*CLK_PERIOD);
        check(o_dbg_stable == 1'b0, "T3 FAILED: release not accepted");
        check(o_led == 1'b1,        "T3 FAILED: 1st release must be ON");

        // T4. Đứng yên ở trạng thái nhả
        #(20*CLK_PERIOD);
        check(o_led == 1'b1, "T4 FAILED: LED changed without release");

        // T5. Nhấn/nhả lần 2
        i_sw_raw = 1'b1; #(1*CLK_PERIOD);
        i_sw_raw = 1'b0; #(1*CLK_PERIOD);
        i_sw_raw = 1'b1;
        #(12*CLK_PERIOD);
        check(o_led == 1'b1, "T5 FAILED: press toggled LED");

        i_sw_raw = 1'b0; #(1*CLK_PERIOD);
        i_sw_raw = 1'b1; #(1*CLK_PERIOD);
        i_sw_raw = 1'b0;
        #(16*CLK_PERIOD);
        check(o_led == 1'b0, "T5 FAILED: 2nd release must be OFF");

        // T6. Reset lại
        i_rst = 1'b1;
        #(2*CLK_PERIOD);
        i_rst = 1'b0;
        #(2*CLK_PERIOD);
        check(o_led == 1'b0, "T6 FAILED: reset did not clear LED");

        if (errors == 0)
            $display("LAB04: ALL SELF-CHECKING TESTS PASSED");
        else
            $display("LAB04: %0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule