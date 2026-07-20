module startup_seq(
    input T, N, B, L, BTN, RST,
    output RTDM, ready, INIT
);

reg T_l, N_l, B_l, L_l;

always @(posedge BTN or posedge RST)
begin
    if(RST)
        {T_l, N_l, B_l, L_l} <= 4'b0000;
    else
        {T_l, N_l, B_l, L_l} <= {T, N, B, L};
end

wire startup_ok;
assign startup_ok = (~T_l) & N_l & B_l & L_l;
assign ready = startup_ok;
localparam OFF = 1'b0;
localparam ON  = 1'b1;

reg state, next_state;

always @(*)
begin
    case(state)
        OFF:
            if(startup_ok)
                next_state = ON;
            else
                next_state = OFF;
        ON:
            next_state = OFF;
        default:
            next_state = OFF;
    endcase
end

always @(negedge BTN or posedge RST)
begin
    if(RST)
        state <= OFF;
    else
        state <= next_state;
end
assign RTDM = state;
assign INIT = (state == OFF) && (next_state == ON);
endmodule