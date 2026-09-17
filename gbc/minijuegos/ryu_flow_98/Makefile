ROM := build/ryu_flow_98.gbc
OBJ := build/ryu_flow_98.o
PYTHON ?= python3

include ../comun/cartucho.mk

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm ../comun/pantalla_cgb.asm $(wildcard assets/*.inc) $(wildcard ../comun/*.asm) | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/ryu_flow_98.sym -o $@ $<
	rgbfix $(RGBFIX_CARTUCHO) $@

test: $(ROM)
	$(PYTHON) test_rom.py

clean:
	rm -rf build
