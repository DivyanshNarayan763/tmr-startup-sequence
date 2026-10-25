module led_flasher(
    input clk, rst, ready,
    output reg RTDM
);

parameter integer CLK_HZ = 32000000;
parameter integer FLASH_HZ = 4;
// One toggle per HALF period; two toggles make one complete blink.
parameter integer COUNT_MAX = CLK_HZ / (2 * FLASH_HZ);
localparam integer COUNT_WIDTH = (COUNT_MAX > 1) ? $clog2(COUNT_MAX) : 1;

reg [COUNT_WIDTH-1:0] count;

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        count <= {COUNT_WIDTH{1'b0}};
        RTDM <= 1'b0;
    end
    else if(!ready)
    begin
        count <= {COUNT_WIDTH{1'b0}};
        RTDM <= 1'b0;
    end
    else
    begin
        if(count == COUNT_MAX - 1)
        begin
            count <= {COUNT_WIDTH{1'b0}};
            RTDM <= ~RTDM;
        end
        else
            count <= count + 1'b1;
    end
end

endmodule
