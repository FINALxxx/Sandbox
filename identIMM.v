/* verilator lint_off UNUSEDSIGNAL */
module identIMM(
    input [31:0] instr,
    input [4:0] imm_sel,
    output [31:0] imm
);
wire [31:0] immI,immU,immS,immB,immJ;
assign immI = {{20{instr[31]}}, instr[31:20]};
assign immU = {instr[31:12], 12'b0};
assign immS = {{20{instr[31]}}, instr[31:25], instr[11:7]};
assign immB = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
assign immJ = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
assign imm = imm_sel[0]? immI :
             imm_sel[1]? immU :
             imm_sel[2]? immS :
             imm_sel[3]? immB : immJ;
endmodule
