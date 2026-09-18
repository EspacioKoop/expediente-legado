ROM := build/dmg_only_smoke.gb
OBJ := build/dmg_only_smoke.o

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
