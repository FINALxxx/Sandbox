#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRISCV_BOARD.h"
#include <iostream>
#include <stdint.h>

VerilatedContext* env = NULL;
VRISCV_BOARD* cpu = NULL;
VerilatedVcdC* tfp = NULL;
vluint64_t sim_time;
svBit ebreak_flag;


void clk_update(){//1clk
	cpu->eval();
	tfp->dump(sim_time);
	sim_time++;
	cpu->clk^=1;

	cpu->eval();	
	tfp->dump(sim_time);
	sim_time++;
	cpu->clk^=1;
}

void half_clk_update(){
	cpu->eval();
	tfp->dump(sim_time);
	sim_time++;
	cpu->clk^=1;
} 

void cpu_init(){
	printf("CPU initizing...\n");
	env = new VerilatedContext;
	cpu = new VRISCV_BOARD(env);
	Verilated::traceEverOn(true);
	tfp = new VerilatedVcdC();
	cpu->trace(tfp,0);
	tfp->open("wave.vcd");
	ebreak_flag = 0;

	cpu->clk   = 0;
	cpu->reset = 1;

	clk_update();
	cpu->reset = 0;
	clk_update();


	printf("CPU initizing completed...\n");
}


uint32_t inst_sram[100] = {
	0x00000413,
	0x00009117,
	0xffc10113,
	0x00c000ef,
	0x00000513,
	0x00008067,
	0xff410113,
	0x00000517,
	0x01c50513,
	0x00000413,//0x00112423,sw指令还没加
	0xfe9ff0ef,
	0x00050513,
	0x00100073,
	0x0000006f
};

extern "C" void terminate(svBit flag);
extern "C" void inst_read(int raddr,int* rdata){
	uint32_t paddr = (raddr - 0x80000000)/4;
	if(paddr > 13){
		terminate(1);
		return;
	}
	*rdata = inst_sram[paddr];
	printf("IN CPP [READ]: addr = %#010x,data = %#010x\n",raddr,*rdata);
}

extern "C" void inst_write(int waddr,int wdata){
	//TODO
}

extern "C" void terminate(svBit flag){
	ebreak_flag = flag;
}

void cpu_terminate(){
	printf("CPU terminating...\n");
	tfp->close();
	cpu->final();
	delete cpu;
	printf("CPU terminating completed\n");
}


void debug(){
	printf("[DEBUG] debug_wb_pc 	 \t= %#010x\n",cpu->debug_wb_pc  	 );
	printf("[DEBUG] debug_wb_rf_wen  \t= %#010x\n",cpu->debug_wb_rf_wen  );
	printf("[DEBUG] debug_wb_rf_waddr\t= %#010x\n",cpu->debug_wb_rf_waddr);
	printf("[DEBUG] debug_wb_rf_wdata\t= %#010x\n",cpu->debug_wb_rf_wdata);
}

int main(){
	cpu_init();
	while(!ebreak_flag){
		clk_update();
		debug();
		printf("----------------1-clk-tick------------------------\n");
	}
	cpu_terminate();
	
	return 0;
}
