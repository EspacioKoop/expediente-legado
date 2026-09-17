ROM := build/ryu_flow_98.gbc
OBJ := build/ryu_flow_98.o
PYTHON ?= python3

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm ../comun/pantalla_cgb.asm $(wildcard assets/*.inc) | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/ryu_flow_98.sym -o $@ $<
	rgbfix -p 255 -v $@

test: $(ROM)
	$(PYTHON) test_rom.py

clean:
	rm -rf build
