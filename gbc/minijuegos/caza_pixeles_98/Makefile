ROM := build/caza_pixeles_98.gbc
OBJ := build/caza_pixeles_98.o
PYTHON ?= python3

include ../comun/cartucho.mk

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm escenario.asm musica.asm cinematicas.asm $(wildcard ../comun/*.asm) | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -o $@ $<
	rgbfix $(RGBFIX_CARTUCHO) $@

test: $(ROM)
	$(PYTHON) test_rom.py

clean:
	rm -rf build
