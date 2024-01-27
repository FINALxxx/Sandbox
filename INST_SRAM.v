/* verilator lint_off UNUSEDSIGNAL */
import "DPI-C" function void inst_read(
	input int raddr,
	output int rdata
);

import "DPI-C" function void inst_write(
	input int waddr,
	input int wdata
);

module INST_SRAM(
    input         clk,
    input         reset,
    input         inst_sram_en,
    input         inst_sram_wen,
    input  [31:0] inst_sram_addr,
    input  [31:0] inst_sram_wdata,
    output [31:0] inst_sram_rdata
);
always_latch @(*) begin//TODO:暂时改成异步，之后记得改为同步
    if(inst_sram_en) begin // 有读写请求时
        inst_read(inst_sram_addr, inst_sram_rdata);
        if (inst_sram_wen) begin // 有写请求时
            inst_write(inst_sram_addr, inst_sram_wdata);
        end
    end
end


endmodule
