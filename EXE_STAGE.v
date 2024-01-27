`include "DEFWIDTH.v"

module EXE_STAGE(
    input clk,
    input reset,
    //allowin
    input mem_allowin,
    output exe_allowin,
    //from id
    input id_to_exe_valid,
    input [`ID_TO_EXE_BUS_WD -1:0] id_to_exe_bus,
    //to mem
    output exe_to_mem_valid,
    output [`EXE_TO_MEM_BUS_WD -1:0] exe_to_mem_bus,

    //for inst_store
    output data_sram_en,
    output data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    output [ 3:0] data_sram_wmask,

    //to id bypass
    output [`EXE_TO_ID_BYPASS_WD -1:0] exe_to_id_bypass,
    output [4:0] exe_to_id_rdbypass,
    output       exe_to_id_rfwenbypass,
    //用于阻塞id段指令的进行
    //原因：当load进行到exe段，而相应的读指令进行到id段，此时读指令需要被阻塞，因为load要到mem段才会执行访存
    output       exe_to_id_loadbypass
);
reg exe_valid;
wire exe_ready_go;
reg [`ID_TO_EXE_BUS_WD -1:0] id_to_exe_bus_r;//接受id到exe的bus的内容

//EXE1,输入
wire [31:0] alu_src1,alu_src2,alu_result;
wire        dst_load,dst_store,dst_writeback;
wire [ 4:0] rd;
wire [10:0] alu_op;
wire [31:0] exe_pc;
wire        exe_ebreak;

assign exe_ready_go = 1'b1;
assign exe_allowin = !exe_valid || (exe_ready_go && mem_allowin);//无阻塞
always_latch @(posedge clk) begin
    if(reset) begin
        exe_valid <= 1'b0;
    end else if(exe_allowin) begin
        exe_valid <= id_to_exe_valid;
    end

    if(id_to_exe_valid && exe_allowin) begin
        id_to_exe_bus_r <= id_to_exe_bus;
    end
end

assign {
    alu_src1,
    alu_src2,
    dst_store,
    dst_load,
    dst_writeback,
    rd,
    alu_op,
    exe_pc,
    exe_ebreak
} = id_to_exe_bus_r;


//EXE2,执行
alu exe_alu(
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .alu_op(alu_op),
    .alu_result(alu_result)
);



//EXE3,store指令
//将RF[rs2]存到MEM[ RF[rs1]+imm ]中
//alu_result = RF[rs1]+imm
assign data_sram_en = 1'b1;
assign data_sram_wen = dst_store && exe_valid;
assign data_sram_addr = alu_result;//load和store都用这个addr（因为load和store不会同时发生）
assign data_sram_wdata = alu_src2;
assign data_sram_wmask = 4'b0001;//TODO:暂时只适配了sb

//EXE4,输出
assign exe_to_mem_valid = exe_valid && exe_ready_go;
assign exe_to_mem_bus = {
    dst_load, //1
    dst_writeback, //1
    alu_result, //32
    rd, //5
    exe_pc, //32
    exe_ebreak //1
};
assign exe_to_id_bypass = alu_result;
assign exe_to_id_rdbypass = rd;
assign exe_to_id_rfwenbypass = dst_writeback;
assign exe_to_id_loadbypass = dst_load;

endmodule
