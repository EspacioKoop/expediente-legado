ROM := build/sarnath_98.gbc
OBJ := build/sarnath_98.o
PYTHON ?= python3

include ../comun/cartucho.mk

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm $(wildcard ../comun/*.asm) | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/sarnath_98.sym -o $@ $<
	rgbfix $(RGBFIX_CARTUCHO) $@

test: $(ROM)
	$(PYTHON) test_rom.py

clean:
	rm -rf build
