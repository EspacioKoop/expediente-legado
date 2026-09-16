ROM := build/webkeeper_98.gbc
OBJ := build/webkeeper_98.o
PYTHON ?= python3

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -n build/webkeeper_98.sym -o $@ $<
	rgbfix -p 255 -v $@

test: $(ROM)
	$(PYTHON) test_rom.py

clean:
	rm -rf build
