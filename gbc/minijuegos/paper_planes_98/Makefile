ROM := build/paper_planes_98.gbc
OBJ := build/paper_planes_98.o

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
