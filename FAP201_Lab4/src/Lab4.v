module lab04 #(
    // 20 ms x 50 MHz = 1,000,000 chu kỳ
    parameter STABLE_CYCLES = 1000000
)(
    input  clk,
    input  i_sw_raw,
    input  i_rst,
    output o_led,
    output o_dbg_stable
);

    // Tính số bit của counter
    function integer clog2;
        input integer n;
        integer value;
        begin
            value = n - 1;
            clog2 = 0;
            while (value > 0) begin
                value = value >> 1;
                clog2 = clog2 + 1;
            end
            if (clog2 == 0)
                clog2 = 1;
        end
    endfunction

    localparam COUNTER_BITS = clog2(STABLE_CYCLES);
    localparam [COUNTER_BITS-1:0] TERMINAL_COUNT = STABLE_CYCLES - 1;

    reg sw_sync1;
    reg sw_sync2;
    reg sw_stable;
    reg [COUNTER_BITS-1:0] stable_count;
    reg evt_cur;
    reg evt_prev;
    reg led_state;

    wire release_event;

    // 1) Lấy mẫu + debounce
    always @(posedge clk) begin
        if (i_rst) begin
            sw_sync1     <= 1'b0;
            sw_sync2     <= 1'b0;
            sw_stable    <= 1'b0;
            stable_count <= {COUNTER_BITS{1'b0}};
        end else begin
            sw_sync1 <= i_sw_raw;
            sw_sync2 <= sw_sync1;

            if (sw_sync2 == sw_stable) begin
                stable_count <= {COUNTER_BITS{1'b0}};
            end else if (stable_count == TERMINAL_COUNT) begin
                sw_stable    <= sw_sync2;
                stable_count <= {COUNTER_BITS{1'b0}};
            end else begin
                stable_count <= stable_count + 1'b1;
            end
        end
    end

    // 2) Phát hiện nhả nút + toggle LED
    assign release_event = evt_prev & ~evt_cur;

    always @(posedge clk) begin
        if (i_rst) begin
            evt_cur   <= 1'b0;
            evt_prev  <= 1'b0;
            led_state <= 1'b0;
        end else begin
            evt_prev <= evt_cur;
            evt_cur  <= sw_stable;
            if (release_event)
                led_state <= ~led_state;
        end
    end

    assign o_led        = led_state;
    assign o_dbg_stable = sw_stable;

endmodule