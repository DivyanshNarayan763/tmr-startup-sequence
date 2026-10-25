module buzzer_timer(
    input clk, rst, init_pulse,
    output reg buzzer
);

parameter integer CLK_HZ = 32000000;
parameter integer RTDS_SECONDS = 2;
parameter integer DURATION = CLK_HZ * RTDS_SECONDS;
localparam integer COUNT_WIDTH = (DURATION > 1) ? $clog2(DURATION) : 1;

reg [COUNT_WIDTH-1:0] count;
reg active;

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        count <= {COUNT_WIDTH{1'b0}};
        active <= 1'b0;
        buzzer <= 1'b0;
    end
    else
    begin
        if(init_pulse && !active)
        begin
            active <= 1'b1;
            count <= {COUNT_WIDTH{1'b0}};
            buzzer <= 1'b1;
        end
        else if(active)
        begin
            if(count == DURATION - 1)
            begin
                active <= 1'b0;
                count <= {COUNT_WIDTH{1'b0}};
                buzzer <= 1'b0;
            end
            else
            begin
                count <= count + 1'b1;
            end
        end
    end
end

endmodule
