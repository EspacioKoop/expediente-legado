ROM := build/aquiles_98.gbc
OBJ := build/aquiles_98.o
SRC := game.asm
PYTHON ?= python3

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): $(SRC) | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/aquiles_98.sym -o $@ $<
	rgbfix -p 255 -v $@

clean:
	rm -rf build

test: $(ROM)
	$(PYTHON) test_rom.py
