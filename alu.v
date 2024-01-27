/* verilator lint_off UNUSEDSIGNAL */
module alu(
    input [31:0] alu_src1,alu_src2,
    input [10:0] alu_op,
    output [31:0] alu_result
);
wire op_add;   //add operation
wire op_sub;   //sub operation
wire op_slt;   //signed compared and set less than
wire op_sltu;  //unsigned compared and set less than
wire op_and;   //bitwise and
wire op_or;    //bitwise or
wire op_xor;   //bitwise xor
wire op_sll;   //logic left shift
wire op_srl;   //logic right shift
wire op_sra;   //arithmetic right shift
wire op_lui;   //Load Upper Immediate

// control code decomposition
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_or   = alu_op[ 5];
assign op_xor  = alu_op[ 6];
assign op_sll  = alu_op[ 7];
assign op_srl  = alu_op[ 8];
assign op_sra  = alu_op[ 9];
assign op_lui  = alu_op[10];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] srl_sra_tmp;//TODO:之后将这个变为32bit的
wire [31:0] srl_sra_result;

/* 32bits adder */
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;
//A-B = A+(-B) = A + (~B+1)
//A+B =        = A + ( B+0)
assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + {31'b0,adder_cin};

//add-sub
assign add_sub_result = adder_result;

//slt-sltu
assign slt_result[31:1] = 31'b0;
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

//bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;//只有一个操作数，执行内容就是输出其本身

//sll-srl-sra
assign sll_result = alu_src1 << alu_src2[4:0];
assign srl_sra_tmp = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0];
assign srl_sra_result = srl_sra_tmp[31:0];

//result mux(TODO:之后将排线形式修改一下，减少排线数和alu_op宽度并且优化mux形式为MUXKEY)
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & srl_sra_result);
endmodule
