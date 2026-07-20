`timescale 1ns/1ps

module startup_controller_tb;

reg T;
reg BRAKE;
reg L;

reg START_BTN;
reg MODE_BTN;
reg RST;

wire RTDM;
wire READY;

wire REV;
wire NEUTRAL;
wire FORWARD;
wire BOOST;

//====================================================
// DUT
//====================================================

startup_controller DUT(

    .T(T),
    .BRAKE(BRAKE),
    .L(L),

    .START_BTN(START_BTN),
    .MODE_BTN(MODE_BTN),

    .RST(RST),

    .RTDM(RTDM),
    .READY(READY),

    .REV(REV),
    .NEUTRAL(NEUTRAL),
    .FORWARD(FORWARD),
    .BOOST(BOOST)

);

//====================================================
// Tasks
//====================================================

task press_start;
begin
    START_BTN = 1;
    #10;
    START_BTN = 0;
    #20;
end
endtask

task press_mode;
begin
    MODE_BTN = 1;
    #10;
    MODE_BTN = 0;
    #20;
end
endtask

//====================================================
// Monitor
//====================================================

initial
begin
    $display("--------------------------------------------------------------");
    $display(" Time\tRTDM READY REV N F BOOST");
    $display("--------------------------------------------------------------");

    $monitor("%4dns\t%b\t%b\t%b  %b %b   %b",
             $time,
             RTDM,
             READY,
             REV,
             NEUTRAL,
             FORWARD,
             BOOST);
end

//====================================================
// Stimulus
//====================================================

initial
begin

    //------------------------------------------------
    // Initial Conditions
    //------------------------------------------------

    T         = 1;
    BRAKE     = 0;
    L         = 0;

    START_BTN = 0;
    MODE_BTN  = 0;

    RST       = 1;

    #20;
    RST = 0;

    //------------------------------------------------
    // Test 1 : Invalid Startup
    //------------------------------------------------

    $display("\nTEST 1 : Invalid Startup");

    press_start;

    //------------------------------------------------
    // Test 2 : Valid Startup
    //------------------------------------------------

    $display("\nTEST 2 : Valid Startup");

    T     = 0;
    BRAKE = 1;
    L     = 1;

    press_start;

    //------------------------------------------------
    // Test 3 : Mode Cycling
    //------------------------------------------------

    $display("\nTEST 3 : Mode Cycling");

    press_mode;      // Forward -> Boost
    press_mode;      // Boost -> Reverse
    press_mode;      // Reverse -> Neutral
    press_mode;      // Neutral -> Forward

    //------------------------------------------------
    // Test 4 : Shutdown
    //------------------------------------------------

    $display("\nTEST 4 : Shutdown");

    press_start;

    //------------------------------------------------
    // Test 5 : Restart without Neutral
    //------------------------------------------------

    $display("\nTEST 5 : Restart without Neutral");

    press_start;

    //------------------------------------------------
    // Test 6 : Move to Neutral then Restart
    //------------------------------------------------

    $display("\nTEST 6 : Restart after selecting Neutral");

    press_mode;      // Forward -> Boost
    press_mode;      // Boost -> Reverse
    press_mode;      // Reverse -> Neutral

    press_start;

    //------------------------------------------------
    // End Simulation
    //------------------------------------------------

    #100;

    $display("\nSimulation Complete.");

    $finish;

end

endmodule