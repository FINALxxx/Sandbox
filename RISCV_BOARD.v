/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNDRIVEN */
module RISCV_BOARD(
    input clk,
    input reset,
    output [31:0] debug_wb_pc,
    output        debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_waddr,
    output [31:0] debug_wb_rf_wdata
);
wire        inst_sram_en,inst_sram_wen;
wire [31:0] inst_sram_addr,inst_sram_wdata,inst_sram_rdata;

wire        data_sram_en,data_sram_wen;
wire [31:0] data_sram_addr,data_sram_wdata,data_sram_rdata;
wire [ 3:0] data_sram_wmask;

RISCV_CPU cpu(
    .clk               (clk              ),
    .reset             (reset            ),

    .inst_sram_en      (inst_sram_en     ),
    .inst_sram_wen     (inst_sram_wen    ),
    .inst_sram_addr    (inst_sram_addr   ),
    .inst_sram_wdata   (inst_sram_wdata  ),
    .inst_sram_rdata   (inst_sram_rdata  ),

    .data_sram_en      (data_sram_en     ),
    .data_sram_wen     (data_sram_wen    ),
    .data_sram_addr    (data_sram_addr   ),
    .data_sram_wdata   (data_sram_wdata  ),
    .data_sram_rdata   (data_sram_rdata  ),
    .data_sram_wmask   (data_sram_wmask  ),

    .debug_wb_pc       (debug_wb_pc      ),
    .debug_wb_rf_wen   (debug_wb_rf_wen  ),
    .debug_wb_rf_waddr (debug_wb_rf_waddr),
    .debug_wb_rf_wdata (debug_wb_rf_wdata)
);

INST_SRAM inst_sram(
    .clk             (clk            ),
    .reset           (reset          ),
    .inst_sram_en    (inst_sram_en   ),
    .inst_sram_wen   (inst_sram_wen  ),
    .inst_sram_addr  (inst_sram_addr ),
    .inst_sram_wdata (inst_sram_wdata),
    .inst_sram_rdata (inst_sram_rdata)
);

endmodule
