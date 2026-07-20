module mode_seq(
    input BTN, INIT, RST,
    output R, N, F, BOOST
);

localparam REV = 2'b00;
localparam NEUTRAL = 2'b01;
localparam FORWARD = 2'b10;
localparam BOOST_STATE = 2'b11;

reg [1:0] state, next_state;

always @(*)
begin
    case(state)
        REV:
            next_state = NEUTRAL;
        NEUTRAL:
            next_state = FORWARD;
        FORWARD:
            next_state = BOOST_STATE;
        BOOST_STATE:
            next_state = REV;
        default:
            next_state = NEUTRAL;
    endcase
end

always @(negedge BTN or posedge INIT or posedge RST)
begin
    if(RST)
        state <= NEUTRAL;

    else if(INIT)
        state <= FORWARD;

    else
        state <= next_state;
end

assign R = (state == REV);
assign N = (state == NEUTRAL);
assign F = (state == FORWARD);
assign BOOST = (state == BOOST_STATE);

endmodule