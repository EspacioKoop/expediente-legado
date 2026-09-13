ROM := build/croc_riders_98.gbc
OBJ := build/croc_riders_98.o

.PHONY: all clean

all: $(ROM)

build:
	mkdir -p build

$(OBJ): main.asm | build
	rgbasm -o $@ $<

$(ROM): $(OBJ)
	rgblink -o $@ $<
	rgbfix -p 255 -v $@

clean:
	rm -rf build
