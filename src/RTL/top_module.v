module startup_controller(
    input clk, rst, START_BTN, MODE_BTN, BOOST_BTN, T, B, N, IMD,
    output READY, RTDS, RTDM, TSAL, REV_LED,
    output [1:0] MODE_OUT
);

parameter integer CLK_HZ = 32000000;
parameter integer RTDS_SECONDS = 2;
parameter integer FLASH_HZ = 4;

parameter REV     = 2'b00,
          NEUTRAL = 2'b01,
          FORWARD = 2'b10,
          BOOST   = 2'b11;

wire start_sync, mode_sync, boost_sync, T_sync, B_sync, N_sync, IMD_sync;
wire start_pulse, mode_pulse, boost_pulse;
wire init_pulse;

// Board reset asserts asynchronously and releases through two clocked stages.
// Keep these stages as separate flops during synthesis and placement.
reg [1:0] reset_ff;
wire core_rst = reset_ff[1];
always @(posedge clk or posedge rst) begin
    if (rst)
        reset_ff <= 2'b11;
    else
        reset_ff <= {reset_ff[0], 1'b0};
end

FF_synch START_SYNC(
    .clk(clk),
    .rst(core_rst),
    .in(START_BTN),
    .out_synced(start_sync)
);

FF_synch MODE_SYNC(
    .clk(clk),
    .rst(core_rst),
    .in(MODE_BTN),
    .out_synced(mode_sync)
);

FF_synch T_SYNC(
    .clk(clk),
    .rst(core_rst),
    .in(T),
    .out_synced(T_sync)
);

FF_synch B_SYNC(
    .clk(clk),
    .rst(core_rst),
    .in(B),
    .out_synced(B_sync)
);

FF_synch N_SYNC(
    .clk(clk),
    .rst(core_rst),
    .in(N),
    .out_synced(N_sync)
);

// Fault assertion is asynchronous; release is synchronized.
// Reset starts faulted until two clocks have sampled IMD high.
reg [1:0] imd_fault_ff;
wire imd_async_set = rst | ~IMD; // IMD LOW means fault.
always @(posedge clk or posedge imd_async_set) begin
    if (imd_async_set)
        imd_fault_ff <= 2'b11;
    else
        imd_fault_ff <= {imd_fault_ff[0], 1'b0};
end
assign IMD_sync = ~imd_fault_ff[1]; // HIGH means healthy.

FF_synch BOOST_SYNC(
    .clk(clk), .rst(core_rst), .in(BOOST_BTN), .out_synced(boost_sync)
);

edge_detector BOOST_EDGE(
    .clk(clk), .rst(core_rst), .signal_in(boost_sync), .signal_out(boost_pulse)
);

edge_detector START_EDGE(
    .clk(clk),
    .rst(core_rst),
    .signal_in(start_sync),
    .signal_out(start_pulse)
);

edge_detector MODE_EDGE(
    .clk(clk),
    .rst(core_rst),
    .signal_in(mode_sync),
    .signal_out(mode_pulse)
);

startup_seq STARTUP(
    .clk(clk),
    .rst(core_rst),
    .start_pulse(start_pulse),
    .T_sync(T_sync),
    .B_sync(B_sync),
    .N_sync(N_sync),
    .IMD_sync(IMD_sync),
    .ready(READY),
    .init_pulse(init_pulse)
);

mode_seq MODE_FSM(
    .clk(clk),
    .rst(core_rst),
    .mode_pulse(mode_pulse),
    .boost_pulse(boost_pulse),
    .ready(READY),
    .init_pulse(init_pulse),
    .mode(MODE_OUT)
);

buzzer_timer #(
    .CLK_HZ(CLK_HZ), .RTDS_SECONDS(RTDS_SECONDS)
) BUZZER_TIMER(
    .clk(clk),
    .rst(core_rst),
    .init_pulse(init_pulse),
    .buzzer(RTDS)
);

led_flasher #(
    .CLK_HZ(CLK_HZ), .FLASH_HZ(FLASH_HZ)
) RTDM_FLASHER(
    .clk(clk),
    .rst(core_rst),
    .ready(READY),
    .RTDM(RTDM)
);

assign TSAL = READY;
assign REV_LED = READY && (MODE_OUT == REV);

endmodule
