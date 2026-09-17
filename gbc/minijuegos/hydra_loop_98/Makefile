ROM := build/hydra_loop_98.gbc
OBJ := build/hydra_loop_98.o
# La portada vive en el directorio de assets integrado por #556.
ASSETS := ../hydra_loop/
PYTHON ?= python3

include ../comun/cartucho.mk

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm $(wildcard $(ASSETS)assets/*) $(wildcard ../comun/*.asm) | build
	rgbasm -I $(ASSETS) -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/hydra_loop_98.sym -o $@ $<
	rgbfix $(RGBFIX_CARTUCHO) $@

test: $(ROM)
	$(PYTHON) test_rom.py

clean:
	rm -rf build
