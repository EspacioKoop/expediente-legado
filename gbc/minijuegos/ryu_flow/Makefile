ROM := build/ryu_flow.gbc
OBJ := build/ryu_flow.o
PYTHON ?= python3

.PHONY: all clean test

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -o $@ $<
	rgbfix -p 255 -v $@

test: $(ROM)
	$(PYTHON) test_rom.py

clean:
	rm -rf build
