.PHONY:sim

CSRC = $(shell find . -name "*.cpp")
VTOP = RISCV_BOARD
VSRC = $(shell find . -name "*.v")
VINC = DEFWIDTH.v


TGS = V${VTOP}

sim:
	rm ./obj_dir -rf
	verilator -Wall --cc --exe -top-module ${VTOP} --build --trace \
	-I${VINC} \
	${CSRC} ${VSRC}
	make -C obj_dir -f ${TGS}.mk ${TGS}
	./obj_dir/${TGS}
