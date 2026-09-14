ROM := build/cgb_only_smoke.gbc
OBJ := build/cgb_only_smoke.o

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
