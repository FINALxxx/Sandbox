import "DPI-C" function void terminate(
	input bit flag
);

module ebreak(
    input clk,
    input reset,
    input flag
);
always @(posedge clk) begin
    if(reset) begin
        terminate(1'b0);
    end else begin
        terminate(flag);
    end
end

endmodule
