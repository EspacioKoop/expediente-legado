ROM := build/hydra_loop_98.gbc
OBJ := build/hydra_loop_98.o
# La portada vive en el directorio de assets integrado por #556.
ASSETS := ../hydra_loop/
PYTHON ?= python3

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm $(wildcard $(ASSETS)assets/*) | build
	rgbasm -I $(ASSETS) -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/hydra_loop_98.sym -o $@ $<
	rgbfix -p 255 -v $@

test: $(ROM)
	$(PYTHON) test_rom.py

clean:
	rm -rf build
