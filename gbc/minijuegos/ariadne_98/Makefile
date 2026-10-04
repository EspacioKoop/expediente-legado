ROM := build/ariadne_98.gbc
OBJ := build/ariadne_98.o
SRC := main.asm

include ../comun/cartucho.mk

.PHONY: all clean

all: $(ROM)

build:
	mkdir -p build

$(OBJ): $(SRC) $(wildcard ../comun/*.asm) | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/ariadne_98.sym -o $@ $<
	rgbfix $(RGBFIX_CARTUCHO) $@

clean:
	rm -rf build
