module FF_synch(
    input clk, rst, in,
    output out_synced
    );
    
reg ff1,ff2;

always@(posedge clk) begin
    if(rst)
        {ff1,ff2} <= 2'b0;
    else begin
        ff1<=in;
        ff2<=ff1;
    end
end

assign out_synced = ff2;
endmodule
