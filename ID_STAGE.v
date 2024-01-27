/* verilator lint_off UNUSEDSIGNAL */

`include "DEFWIDTH.v"

module ID_STAGE(
    input clk,
    input reset,
    //allowin
    output id_allowin,
    input exe_allowin,
    //from if
    input if_to_id_valid,
    input [`IF_TO_ID_BUS_WD -1:0] if_to_id_bus,
    //to exe
    output id_to_exe_valid,
    output [`ID_TO_EXE_BUS_WD -1:0] id_to_exe_bus,
    //to if(for branch)
    output [`ID_TO_IF_BRBUS_WD -1:0] id_to_if_brbus,
    //from wb(for reg)
    input [`WB_TO_ID_RFBUS_WD -1:0] wb_to_id_rfbus,

    //bypass
    input [`MEM_TO_ID_BYPASS_WD -1:0] exe_to_id_bypass,
    input [4:0] exe_to_id_rdbypass,
    input       exe_to_id_rfwenbypass,
    input [`MEM_TO_ID_BYPASS_WD -1:0] mem_to_id_bypass,
    input [4:0] mem_to_id_rdbypass,
    input       mem_to_id_rfwenbypass,
    input [`WB_TO_ID_BYPASS_WD  -1:0] wb_to_id_bypass,
    input [4:0] wb_to_id_rdbypass,
    input       wb_to_id_rfwenbypass,

    //blocking bypass
    input      exe_to_id_loadbypass
);

//通路
wire [31:0] id_pc,id_inst;
reg id_valid;
wire id_ready_go;
reg  [`IF_TO_ID_BUS_WD -1:0] if_to_id_bus_r;//接受if到id的bus的内容
wire [31:0] src1,src2;


//ID阶段1,处理输入
assign id_ready_go = ~exe_to_id_loadbypass;
assign id_allowin = !id_valid || (id_ready_go && exe_allowin);//可以接受新的输入数据 = 无数据时（待初始化） || 有数据但流水线不阻塞时（数据可以流向下一级以腾出空位）
wire [4:0] op;
wire [4:0] rs1,rs2,rd;
wire [2:0] func3;
wire func7;
always @(posedge clk) begin
    if(reset) begin
        id_valid <= 1'b0;
    end else if(id_allowin) begin
        id_valid <= if_to_id_valid;//如果if不往id传值，则也为无效
    end

    if(if_to_id_valid && id_allowin) begin
        if_to_id_bus_r <= if_to_id_bus;//接受if传来的数据
    end
end
assign {id_inst, id_pc} = if_to_id_bus_r;
assign op  = id_inst[6:2];
assign rs1 = id_inst[19:15];
assign rs2 = id_inst[24:20];
assign rd  = id_inst[11:7];
assign func3  = id_inst[14:12];
assign func7  = id_inst[30];

assign {
    rf_wen,
    rf_waddr,
    rf_wdata
} = wb_to_id_rfbus;//写回输入


//ID阶段2,指令识别
wire [ 4:0] imm_sel;
wire [ 1:0] src1_sel;
wire [ 2:0] src2_sel;
wire [ 2:0] dst_sel;
wire [10:0] alu_op;
wire        id_branch,branch_rs1_eq_rd;
wire        id_jal,id_jalr;
wire        id_ebreak;

assign branch_rs1_eq_rd = rf_rdata1 == rf_rdata2;

decoder id_dec(
    .op(op),
    .op3({op,func3}),
    .op37({op,func3,func7}),
    .imm_sel(imm_sel),
    .src1_sel(src1_sel),
    .src2_sel(src2_sel),
    .dst_sel(dst_sel),
    .alu_op(alu_op),
    //branch
    .branch_rs1_eq_rd(branch_rs1_eq_rd),
    .branch(id_branch),
    //jump
    .jal(id_jal),
    .jalr(id_jalr),
    //ebreak
    .op_ebreak(id_inst[20]),
    .ebreak(id_ebreak)
);

//ID阶段3,立即数识别
wire [31:0] imm;
identIMM id_identIMM(
    .instr(id_inst),
    .imm_sel(imm_sel),
    .imm(imm)
);

//ID阶段4,寄存器读写

wire rf_wen;
wire [4:0] rf_raddr1,rf_raddr2,rf_waddr;
wire [31:0] rf_rdata1,rf_rdata2,rf_wdata;

assign rf_raddr1 = rs1;
assign rf_raddr2 = rs2;

RegisterFile id_rf(
    .clk     (clk      ),
    .raddr_a (rf_raddr1),
    .rdata_a (rf_rdata1),
    .raddr_b (rf_raddr2),
    .rdata_b (rf_rdata2),
    .wen     (rf_wen   ),
    .waddr   (rf_waddr ),
    .wdata   (rf_wdata )
);

//ID阶段5,处理输出
assign id_to_exe_valid = id_valid && id_ready_go;

wire [31:0] rdata1,rdata2;
wire exe_rd_eq_rs1,exe_rd_eq_rs2;
wire mem_rd_eq_rs1,mem_rd_eq_rs2;
wire wb_rd_eq_rs1,wb_rd_eq_rs2;

assign exe_rd_eq_rs1 = exe_to_id_rdbypass == rs1;
assign exe_rd_eq_rs2 = exe_to_id_rdbypass == rs2;
assign mem_rd_eq_rs1 = mem_to_id_rdbypass == rs1;
assign mem_rd_eq_rs2 = mem_to_id_rdbypass == rs2;
assign wb_rd_eq_rs1  = wb_to_id_rdbypass  == rs1;
assign wb_rd_eq_rs2  = wb_to_id_rdbypass  == rs2;

//旁路优先选择器
assign rdata1 = (exe_to_id_rfwenbypass & exe_rd_eq_rs1) ? exe_to_id_bypass :
                (mem_to_id_rfwenbypass & mem_rd_eq_rs1) ? mem_to_id_bypass :
                (wb_to_id_rfwenbypass  & wb_rd_eq_rs1 ) ? wb_to_id_bypass  : rf_rdata1;

assign rdata2 = (exe_to_id_rfwenbypass & exe_rd_eq_rs2) ? exe_to_id_bypass :
                (mem_to_id_rfwenbypass & mem_rd_eq_rs2) ? mem_to_id_bypass :
                (wb_to_id_rfwenbypass  & wb_rd_eq_rs2 ) ? wb_to_id_bypass  : rf_rdata2;

assign src1 = src1_sel[0] ? rdata1 : id_pc;
assign src2 = src2_sel[0] ? imm    :
              src2_sel[1] ? rdata2 : 32'h4;
assign id_to_exe_bus = {
    src1, //32
    src2, //32
    dst_sel, //3
    rd, //5
    alu_op, //11
    id_pc, //32
    id_ebreak //1
};


wire        id_br_jmp;
wire [31:0] id_jalr_dst,id_br_jmp_dst;
assign id_br_jmp = (id_branch || id_jal || id_jalr) && id_valid;
assign id_jalr_dst = rf_rdata1 + imm;
assign id_br_jmp_dst = (id_branch || id_jal) ? id_pc + imm : {id_jalr_dst[31:1],1'b0};

assign id_to_if_brbus = {
    id_br_jmp ,//1
    id_br_jmp_dst //32
};

endmodule
