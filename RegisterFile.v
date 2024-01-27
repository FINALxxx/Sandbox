module RegisterFile #(DATA_WIDTH=32,REG_NUM=32,REG_NUM_BIT=5)  (
  //ADDR_WIDTH个寄存器，每个寄存器保存DATA_WIDTH个bits
  input clk,
  input [REG_NUM_BIT-1:0] raddr_a,//读rs1
  input [REG_NUM_BIT-1:0] raddr_b,//读rs2
  output [DATA_WIDTH-1:0] rdata_a,//读rs1
  output [DATA_WIDTH-1:0] rdata_b,//读rs2

  input wen,//写使能
  input [REG_NUM_BIT-1:0] waddr,//写rd
  input [DATA_WIDTH-1:0] wdata//写rd
);
  reg [DATA_WIDTH-1:0] rf [REG_NUM-1:0];
  always @(posedge clk) begin
    if (wen) rf[waddr] <= wdata;
  end
  
  assign rdata_a = (raddr_a=='b0) ? 'b0 : rf[raddr_a];
  assign rdata_b = (raddr_b=='b0) ? 'b0 : rf[raddr_b];
endmodule
