
// Check these named port connections against your current top module.
// Assumes an active-HIGH reset named rst and active-HIGH button inputs.
module tb_simple;
    reg clk, rst;
    reg START_BTN, MODE_BTN, BOOST_BTN;
    reg T, B, N, IMD;
    wire READY, RTDS, RTDM;
    wire [1:0] MODE_OUT;
    integer test_case;

    startup_controller #(.CLK_HZ(32000000)) dut (
        .clk(clk), .rst(rst),
        .START_BTN(START_BTN), .MODE_BTN(MODE_BTN),
        .BOOST_BTN(BOOST_BTN),
        .T(T), .B(B), .N(N), .IMD(IMD),
        .READY(READY), .MODE_OUT(MODE_OUT),
        .RTDS(RTDS), .RTDM(RTDM)
    );

    // 32 MHz: 31.25 ns period.
    initial clk = 0;
    always #15.625 clk = ~clk;

    // Change inputs on falling edges to avoid races with the DUT.
    task wait_cycles;
        input integer count;
        begin
            repeat (count) @(negedge clk);
        end
    endtask

    // mask[2:0] = {START, MODE, BOOST}
    task press;
        input [2:0] mask;
        begin
            @(negedge clk);
            {START_BTN, MODE_BTN, BOOST_BTN} = mask;
            wait_cycles(8);
            {START_BTN, MODE_BTN, BOOST_BTN} = 3'b000;
            wait_cycles(12);
        end
    endtask

    initial begin
        // Only dump top-level signals; add dut.init_pulse in the GUI
        // if that internal signal exists in your current RTL.
        $dumpfile("tb_simple.vcd");
        $dumpvars(1, tb_simple);
    end

    initial begin
        rst = 1;
        START_BTN = 0; MODE_BTN = 0; BOOST_BTN = 0;
        T = 0; B = 1; N = 1; IMD = 1;
        test_case = 0;
        wait_cycles(8);
        rst = 0;
        wait_cycles(12);

        test_case = 1; // Throttle nonzero: startup rejected.
        T = 1; wait_cycles(8); press(3'b100);
        T = 0; wait_cycles(8);

        test_case = 2; // Brake not fully pressed: startup rejected.
        B = 0; wait_cycles(8); press(3'b100);
        B = 1; wait_cycles(8);

        test_case = 3; // Not Neutral: startup rejected.
        N = 0; wait_cycles(8); press(3'b100);
        N = 1; wait_cycles(8);

        test_case = 4; // IMD fault: startup rejected.
        IMD = 0; wait_cycles(8); press(3'b100);
        IMD = 1; wait_cycles(12);

        test_case = 5; // BOOST while OFF: ignored.
        press(3'b001);

        test_case = 6; // Valid startup: READY HIGH, Forward selected.
        press(3'b100);

        test_case = 7; // Forward -> Boost -> Forward.
        press(3'b001);
        press(3'b001);

        test_case = 8; // MODE exits Boost to next normal mode.
        press(3'b001);
        press(3'b010);

        test_case = 9; // BOOST ignored in both non-Forward modes.
        press(3'b001);
        press(3'b010);
        press(3'b001);
        press(3'b010); // Back to Forward after full normal cycle.

        test_case = 10; // Simultaneous MODE + BOOST: MODE wins.
        press(3'b011);

        test_case = 11; // Qualifiers alone do not switch OFF.
        T = 1; B = 0; N = 0;
        wait_cycles(16);

        test_case = 12; // START switches OFF despite bad qualifiers.
        press(3'b100);
        T = 0; B = 1; N = 1;
        wait_cycles(12);

        test_case = 13; // Restart, enter Boost, then fault between edges.
        press(3'b100);
        press(3'b001);
        #5 IMD = 0;
        wait_cycles(12);

        test_case = 14; // IMD recovers: remain OFF without START.
        IMD = 1;
        wait_cycles(24);

        test_case = 15; // Held START causes only one startup event.
        START_BTN = 1;
        wait_cycles(32);
        START_BTN = 0;
        wait_cycles(12);

        test_case = 16; // Reset while ON: READY returns LOW.
        rst = 1;
        wait_cycles(8);
        rst = 0;
        wait_cycles(16);

        $finish;
    end
endmodule
