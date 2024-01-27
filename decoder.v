/* verilator lint_off UNOPTFLAT */
module decoder(
    input  [ 4:0] op,
    input  [ 7:0] op3,
    input  [ 8:0] op37,
    output [ 4:0] imm_sel,
    output [ 1:0] src1_sel,
    output [ 2:0] src2_sel,
    output [ 2:0] dst_sel,
    output [10:0] alu_op,

    //branch
    input         branch_rs1_eq_rd,
    output        branch,

    //jump
    output        jal,
    output        jalr,

    //store&load
    //output [4:0] load_op,
    //output [2:0] store_op,

    //ebreak
    input         op_ebreak,//位于instr[20]
    output        ebreak
);
//输入选择
wire src1_is_pc,src1_is_rs1;
wire src2_is_imm,src2_is_rs2,src2_is_4;
//输出选择
wire dst_store,dst_load,dst_writeback;
//指令(TODO)
wire inst_lui,
     inst_auipc;

wire inst_add,
     inst_addi,
     inst_sub;

//debug:riscv没有nor和nori
wire inst_and,
     inst_andi,
     inst_or,
     inst_ori,
     inst_xor,
     inst_xori;

wire inst_slt,
     inst_slti,
     inst_sltu,
     inst_sltiu;

wire inst_sll,//逻辑左移
     inst_slli,
     inst_srl,//逻辑右移
     inst_srli,
     inst_sra,//算术右移
     inst_srai;

wire inst_jal,
     inst_jalr,
     inst_beq,
     inst_bne,
     inst_blt;

wire inst_lb,
     inst_lbu,
     inst_sb;

assign inst_lui = op==5'b01101;
assign inst_auipc = op==5'b00101;

assign inst_add = op37==9'b01100_000_0;
assign inst_addi = op3==8'b00100_000;
assign inst_sub = op37==9'b01100_000_1;


assign inst_and = op37==9'b01100_111_0;
assign inst_andi = op3==8'b00100_111;
assign inst_or = op37==9'b01100_110_0;
assign inst_ori = op3==8'b01100_110;
assign inst_xor = op37==9'b01100_100_0;
assign inst_xori = op3==8'b01100_100;

assign inst_slt = op37==9'b01100_010_0;
assign inst_slti = op3==8'b00100_010;
assign inst_sltu = op37==9'b01100_011_0;
assign inst_sltiu = op3==8'b00100_011;

assign inst_sll = op37==9'b01100_001_0;
assign inst_slli = op37==9'b00100_001_0;
assign inst_srl = op37==9'b01100_101_0;
assign inst_srli = op37==9'b00100_101_0;
assign inst_sra = op37==9'b01100_101_1;
assign inst_srai = op37==9'b00100_101_1;

assign inst_jal = op==5'b11011;
assign inst_jalr = op3==8'b11001_000;//TODO
assign inst_beq = op3==8'b11000_000;
assign inst_bne = op3==8'b11000_001;
assign inst_blt = op3==8'b11000_100;//TODO

assign inst_lb = op3==8'b00000_000;
assign inst_lbu = op3==8'b00000_100;
assign inst_sb = op3==8'b01000_000;

//src1
assign src1_is_pc = inst_auipc | inst_jal | inst_jalr;
assign src1_is_rs1 = ~src1_is_pc;

//src2
assign src2_is_4 = inst_jal | inst_jalr;
assign src2_is_imm = ~src2_is_rs2;
assign src2_is_rs2 = inst_add | inst_sub | inst_sll | inst_slt | inst_sltu | inst_xor | inst_srl | inst_sra | inst_or | inst_and;

//dst
assign dst_store = inst_sb;
assign dst_load = inst_lb | inst_lbu;
assign dst_writeback = ~dst_store | ~inst_beq | ~inst_bne | ~inst_blt;//writeback包含load写回rf和直接写回rf

//alu_op
assign alu_op[ 0] = inst_add | inst_addi | inst_lb | inst_lbu | inst_sb | inst_jal | inst_jalr | inst_auipc;//alu add
assign alu_op[ 1] = inst_sub;//alu sub
assign alu_op[ 2] = inst_slt | inst_slti;//alu signed comp
assign alu_op[ 3] = inst_sltu | inst_sltiu;//alu unsigned comp
assign alu_op[ 4] = inst_and | inst_andi;//alu and
assign alu_op[ 5] = inst_or | inst_ori;//alu or
assign alu_op[ 6] = inst_xor | inst_xori;//alu xor
assign alu_op[ 7] = inst_sll | inst_slli;//alu shift left logically
assign alu_op[ 8] = inst_srl | inst_srli;//alu shift right logically
assign alu_op[ 9] = inst_sra | inst_srai;//alu shift right arithmetically
assign alu_op[10] = inst_lui;//alu lui(只有一个操作数，执行内容就是输出其本身)

//imm_sel
assign imm_sel[0] = ~(|imm_sel[4:1]);//I 出现circular logic(WARN UNOPTFLAT)
assign imm_sel[1] = inst_auipc | inst_lui;//U
assign imm_sel[2] = inst_sb;//S
assign imm_sel[3] = inst_beq | inst_bne | inst_blt;//B
assign imm_sel[4] = inst_jal;//J

//src_sel and dst_sel
assign src1_sel = {src1_is_pc,src1_is_rs1};
assign src2_sel = {src2_is_4,src2_is_rs2,src2_is_imm};
assign dst_sel = {dst_store,dst_load,dst_writeback};


//TODO:load_op and store_op



//TODO:branch
assign branch = (
    inst_beq && branch_rs1_eq_rd
||  inst_bne && !branch_rs1_eq_rd
);

//TODO:jump
assign jal = inst_jal;
assign jalr = inst_jalr;


//ebreak
assign ebreak = op3 == 8'b11100_000 && op_ebreak;

endmodule
