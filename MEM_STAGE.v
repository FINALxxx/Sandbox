`include "DEFWIDTH.v"

module MEM_STAGE(
    input clk,
    input reset,
    //allowin
    output mem_allowin,
    input wb_allowin,
    //from exe
    input exe_to_mem_valid,
    input [`EXE_TO_MEM_BUS_WD -1:0] exe_to_mem_bus,
    //to wb
    output mem_to_wb_valid,
    output [`MEM_TO_WB_BUS_WD -1:0] mem_to_wb_bus,
    //inst_load
    input [31:0] data_sram_rdata,

    //to id bypass
    output [`MEM_TO_ID_BYPASS_WD -1:0] mem_to_id_bypass,
    output [4:0] mem_to_id_rdbypass,
    output       mem_to_id_rfwenbypass
);
reg mem_valid;
wire mem_ready_go;

reg [`EXE_TO_MEM_BUS_WD -1:0] exe_to_mem_bus_r;

wire        dst_load,dst_writeback;
wire [ 4:0] rd;
wire [31:0] alu_result,writeback_result;
wire [31:0] mem_pc;
wire        mem_ebreak;

//MEM1,输入
assign mem_ready_go = 1'b1;
assign mem_allowin = !mem_valid || (mem_ready_go && wb_allowin);
always @(posedge clk) begin
    if(reset) begin
        mem_valid <= 1'b0;
    end else if(mem_allowin) begin
        mem_valid <= exe_to_mem_valid;
    end

    if(mem_allowin && exe_to_mem_valid) begin
        exe_to_mem_bus_r <= exe_to_mem_bus;
    end
end

assign {
    dst_load,
    dst_writeback,
    alu_result,
    rd,
    mem_pc,
    mem_ebreak
} = exe_to_mem_bus_r;

//MEM2,区分load指令写回与直接写回(均属于writeback方式)
//load:将MEM[ RF[rs1]+imm ]读到RF[rd]中
//     MEM[ RF[rs1]+imm ] = data_sram_rdata
//direct:将alu_result直接写回到RF[rd]中
assign writeback_result = dst_load ? data_sram_rdata : alu_result;

//MEM3,输出
assign mem_to_wb_valid = mem_valid && mem_ready_go;
assign mem_to_wb_bus = {
    dst_writeback, //1
    rd, //5
    writeback_result, //32
    mem_pc, //32
    mem_ebreak //1
};
assign mem_to_id_bypass = writeback_result;
assign mem_to_id_rdbypass = rd;
assign mem_to_id_rfwenbypass = dst_writeback;

endmodule
