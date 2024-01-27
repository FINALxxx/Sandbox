`include "DEFWIDTH.v"

module IF_STAGE(
    input clk,
    input reset,
    //allowin
    input id_allowin,
    //to id
    output if_to_id_valid,
    output [`IF_TO_ID_BUS_WD -1:0] if_to_id_bus,
    //from id(for branch)
    input  [`ID_TO_IF_BRBUS_WD -1:0] id_to_if_brbus,
    //to inst_mem
    output inst_sram_en,//指令内存：读写使能
    output [31:0] inst_sram_addr,
    output inst_sram_wen,//指令内存：写使能
    output [31:0] inst_sram_wdata,
    //from inst_mem
    input  [31:0] inst_sram_rdata
);

//pre-IF
wire preif_to_if_valid;
wire [31:0] snpc;
wire [31:0] dnpc;
wire [31:0] if_inst;
reg  [31:0] if_pc;//当前pc
wire br_jmp;
wire [31:0] br_jmp_dst;

assign preif_to_if_valid = ~reset;
assign snpc = if_pc + 32'h4;

assign {br_jmp,br_jmp_dst} = id_to_if_brbus;
assign dnpc = br_jmp ? br_jmp_dst : snpc ;

//IF
reg if_valid;
wire if_allowin,if_ready_go;


assign if_ready_go = 1'b1;//主动控制当前流水段是否阻塞
assign if_allowin = !if_valid || (if_ready_go && id_allowin);//是否允许采纳if阶段的缓存（dnpc）作为输入
assign if_to_id_valid = if_valid && if_ready_go;//是否允许发送数据到下一个阶段的缓存


//IF阶段,处理输入
always @(posedge clk) begin
    if(reset) begin
        if_valid <= 1'b0;
    end else if(if_allowin) begin
        if_valid <= preif_to_if_valid;
    end
end

//IF阶段,处理输出
always @(posedge clk) begin
    if(reset) begin
        if_pc <= 32'h7FFF_FFFC;//trick
    end else if(if_to_id_valid) begin
        if_pc <= dnpc;
    end

end

assign inst_sram_en = preif_to_if_valid && if_allowin;//不阻塞
assign inst_sram_wen = 1'b0;
assign inst_sram_addr = dnpc;
assign if_inst = inst_sram_rdata;
assign inst_sram_wdata = 32'b0;
assign if_to_id_bus = {if_inst, if_pc};
endmodule
