`include "DEFWIDTH.v"

module RISCV_CPU(
    input clk,
    input reset,
    //inst sram
    output        inst_sram_en,
    output        inst_sram_wen,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,

    //data sram
    output        data_sram_en,
    output        data_sram_wen,
    output [31:0] data_sram_addr,
    output [ 3:0] data_sram_wmask,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,

    //debug
    output [31:0] debug_wb_pc,
    output        debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_waddr,
    output [31:0] debug_wb_rf_wdata
);
wire id_allowin;
wire exe_allowin;
wire mem_allowin;
wire wb_allowin;
wire if_to_id_valid;
wire id_to_exe_valid;
wire exe_to_mem_valid;
wire mem_to_wb_valid;
wire [`IF_TO_ID_BUS_WD -1:0]   if_to_id_bus;
wire [`ID_TO_EXE_BUS_WD -1:0]  id_to_exe_bus;
wire [`EXE_TO_MEM_BUS_WD -1:0] exe_to_mem_bus;
wire [`MEM_TO_WB_BUS_WD -1:0]  mem_to_wb_bus;
wire [`ID_TO_IF_BRBUS_WD -1:0] id_to_if_brbus;
wire [`WB_TO_ID_RFBUS_WD -1:0] wb_to_id_rfbus;

wire [`WB_TO_ID_BYPASS_WD -1:0] exe_to_id_bypass;
wire [4:0] exe_to_id_rdbypass;
wire       exe_to_id_rfwenbypass;
wire [`MEM_TO_ID_BYPASS_WD -1:0] mem_to_id_bypass;
wire [4:0] mem_to_id_rdbypass;
wire       mem_to_id_rfwenbypass;
wire [`WB_TO_ID_BYPASS_WD -1:0] wb_to_id_bypass;
wire [4:0] wb_to_id_rdbypass;
wire       wb_to_id_rfwenbypass;

wire exe_to_id_loadbypass;


// IF stage
IF_STAGE if_stage(
    .clk             (clk            ),
    .reset           (reset          ),
    //allowin
    .id_allowin      (id_allowin     ),
    //to id
    .if_to_id_valid  (if_to_id_valid ),
    .if_to_id_bus    (if_to_id_bus   ),
    //from id(for branch)
    .id_to_if_brbus  (id_to_if_brbus ),
    //from inst sram
    .inst_sram_en    (inst_sram_en   ),
    .inst_sram_addr  (inst_sram_addr ),
    .inst_sram_rdata (inst_sram_rdata),
    //to inst sram
    .inst_sram_wen   (inst_sram_wen  ),
    .inst_sram_wdata (inst_sram_wdata)

);

// ID stage
ID_STAGE id_stage(
    .clk             (clk            ),
    .reset           (reset          ),
    //allowin
    .exe_allowin     (exe_allowin    ),
    .id_allowin      (id_allowin     ),
    //from if
    .if_to_id_valid  (if_to_id_valid ),
    .if_to_id_bus    (if_to_id_bus   ),
    //to exe
    .id_to_exe_valid (id_to_exe_valid),
    .id_to_exe_bus   (id_to_exe_bus  ),
    //to if(for branch)
    .id_to_if_brbus  (id_to_if_brbus ),
    //from wb(for reg)
    .wb_to_id_rfbus  (wb_to_id_rfbus ),

    //from exe bypass
    .exe_to_id_bypass      (exe_to_id_bypass     ),
    .exe_to_id_rdbypass    (exe_to_id_rdbypass   ),
    .exe_to_id_rfwenbypass (exe_to_id_rfwenbypass),

    //from mem bypass
    .mem_to_id_bypass      (mem_to_id_bypass     ),
    .mem_to_id_rdbypass    (mem_to_id_rdbypass   ),
    .mem_to_id_rfwenbypass (mem_to_id_rfwenbypass),

    //from wb bypass
    .wb_to_id_bypass       (wb_to_id_bypass      ),
    .wb_to_id_rdbypass     (wb_to_id_rdbypass    ),
    .wb_to_id_rfwenbypass  (wb_to_id_rfwenbypass ),

    //blocking bypass
    .exe_to_id_loadbypass  (exe_to_id_loadbypass )
);

// EXE stage
EXE_STAGE exe_stage(
    .clk              (clk             ),
    .reset            (reset           ),
    //allowin
    .mem_allowin      (mem_allowin     ),
    .exe_allowin      (exe_allowin     ),
    //from id
    .id_to_exe_valid  (id_to_exe_valid ),
    .id_to_exe_bus    (id_to_exe_bus   ),
    //to mem
    .exe_to_mem_valid (exe_to_mem_valid),
    .exe_to_mem_bus   (exe_to_mem_bus  ),
    //to data sram(for inst_store)
    .data_sram_en     (data_sram_en    ),
    .data_sram_wen    (data_sram_wen   ),
    .data_sram_addr   (data_sram_addr  ),
    .data_sram_wdata  (data_sram_wdata ),
    .data_sram_wmask  (data_sram_wmask ),

    //to id bypass
    .exe_to_id_bypass      (exe_to_id_bypass     ),
    .exe_to_id_rdbypass    (exe_to_id_rdbypass   ),
    .exe_to_id_rfwenbypass (exe_to_id_rfwenbypass),

    //blocking bypass
    .exe_to_id_loadbypass  (exe_to_id_loadbypass )
);

// MEM stage
MEM_STAGE mem_stage(
    .clk                   (clk             ),
    .reset                 (reset           ),
    //allowin
    .wb_allowin            (wb_allowin      ),
    .mem_allowin           (mem_allowin     ),
    //from exe
    .exe_to_mem_valid      (exe_to_mem_valid),
    .exe_to_mem_bus        (exe_to_mem_bus  ),
    //to wb
    .mem_to_wb_valid       (mem_to_wb_valid ),
    .mem_to_wb_bus         (mem_to_wb_bus   ),
    //from data sram(for inst_load)
    .data_sram_rdata       (data_sram_rdata ),

    //to id bypass
    .mem_to_id_bypass      (mem_to_id_bypass     ),
    .mem_to_id_rdbypass    (mem_to_id_rdbypass   ),
    .mem_to_id_rfwenbypass (mem_to_id_rfwenbypass)
);

// WB stage
WB_STAGE wb_stage(
    .clk                  (clk              ),
    .reset                (reset            ),
    //allowin
    .wb_allowin           (wb_allowin       ),
    //from mem
    .mem_to_wb_valid      (mem_to_wb_valid  ),
    .mem_to_wb_bus        (mem_to_wb_bus    ),
    //to id (for reg)
    .wb_to_id_rfbus       (wb_to_id_rfbus   ),
    //trace debug interface
    .debug_wb_pc          (debug_wb_pc      ),
    .debug_wb_rf_wen      (debug_wb_rf_wen  ),
    .debug_wb_rf_waddr    (debug_wb_rf_waddr),
    .debug_wb_rf_wdata    (debug_wb_rf_wdata),

    //to id bypass
    .wb_to_id_bypass      (wb_to_id_bypass     ),
    .wb_to_id_rdbypass    (wb_to_id_rdbypass   ),
    .wb_to_id_rfwenbypass (wb_to_id_rfwenbypass)
);

endmodule
