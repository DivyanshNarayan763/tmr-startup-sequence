module mode_seq(
    input clk, rst, mode_pulse, boost_pulse, init_pulse, ready,
    output reg [1:0] mode
);
parameter REV = 2'b00,
          NEUTRAL = 2'b01,
          FORWARD = 2'b10,
          BOOST = 2'b11;

always @(posedge clk or posedge rst) begin
    if (rst)
        mode <= NEUTRAL;
    else if (init_pulse && ready)
        mode <= FORWARD;
    // MODE wins if both MODE and BOOST are pressed together.
    else if (mode_pulse) begin
        case (mode)
            REV:     mode <= NEUTRAL;
            NEUTRAL: mode <= FORWARD;
            FORWARD: mode <= REV;
            BOOST:   mode <= REV;
            default: mode <= NEUTRAL;
        endcase
    end else if (!ready && mode == BOOST)
        mode <= FORWARD; // Boost cannot remain selected while OFF.
    else if (boost_pulse && ready) begin
        case (mode)
            FORWARD: mode <= BOOST;
            BOOST:   mode <= FORWARD;
            default: mode <= mode;
        endcase
    end
end
endmodule
