ROM := build/croc_riders_98.gbc
OBJ := build/croc_riders_98.o
SRC := game.asm

.PHONY: all clean

all: $(ROM)

build:
	mkdir -p build

$(OBJ): $(SRC) | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -o $@ $<
	rgbfix -p 255 -v $@

clean:
	rm -rf build
