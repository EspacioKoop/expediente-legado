ROM := build/croc_riders_98.gbc
OBJ := build/croc_riders_98.o
SRC := game.asm
PYTHON ?= python3

include ../comun/cartucho.mk

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): $(SRC) $(wildcard ../comun/*.asm) | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/croc_riders_98.sym -o $@ $<
	rgbfix $(RGBFIX_CARTUCHO) $@

clean:
	rm -rf build

test: $(ROM)
	$(PYTHON) test_rom.py
