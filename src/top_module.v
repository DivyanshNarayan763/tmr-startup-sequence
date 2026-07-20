module startup_controller(
    input T,BRAKE,L,START_BTN,MODE_BTN,RST,
    output RTDM,READY,REV,NEUTRAL,FORWARD,BOOST
);

wire N, INIT;

startup_seq STARTUP(
    .T(T),
    .N(N),
    .B(BRAKE),
    .L(L),
    .BTN(START_BTN),
    .RST(RST),
    .RTDM(RTDM),
    .ready(READY),
    .INIT(INIT)
);

mode_seq MODE(
    .BTN(MODE_BTN),
    .INIT(INIT),
    .RST(RST),
    .R(REV),
    .N(N),
    .F(FORWARD),
    .BOOST(BOOST)
);

assign NEUTRAL = N;

endmodule