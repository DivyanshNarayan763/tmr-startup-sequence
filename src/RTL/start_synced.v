module startup_seq(
    input clk, rst, start_pulse, T_sync, B_sync, N_sync, IMD_sync,
    output ready, init_pulse
);

reg started;
reg init_pulse_reg;
wire startup_ok = ~T_sync & B_sync & N_sync & IMD_sync;

wire shutdown_reset = rst | ~IMD_sync;

always @(posedge clk or posedge shutdown_reset) begin
    if (shutdown_reset) begin
        started <= 1'b0;
        init_pulse_reg <= 1'b0;
    end else begin
        init_pulse_reg <= 1'b0;
        // IMD has priority over every button action.
        if (start_pulse) begin
            if (started)
                started <= 1'b0;
            else if (startup_ok) begin
                started <= 1'b1;
                init_pulse_reg <= 1'b1;
            end
        end
    end
end

assign ready = started;
assign init_pulse = init_pulse_reg;
endmodule
