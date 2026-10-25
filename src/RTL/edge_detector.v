module edge_detector(
    input clk, rst, signal_in,
    output signal_out
);

reg signal_prev;
always @(posedge clk) begin
    if(rst)
        signal_prev <= 1'b0;
    else
        signal_prev <= signal_in;
end

assign signal_out = signal_in & ~signal_prev;
endmodule
