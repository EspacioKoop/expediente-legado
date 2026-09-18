ROM_A := build/sram_a.gbc
ROM_B := build/sram_b.gbc
OBJ_A := build/sram_a.o
OBJ_B := build/sram_b.o
RGBFIX_CARTUCHO := -m 0x1B -r 0x02 -p 255 -v

.PHONY: all clean

all: $(ROM_A) $(ROM_B)

build:
	mkdir -p build

$(OBJ_A): a.asm main.asm | build
	rgbasm -o $@ a.asm

$(OBJ_B): b.asm main.asm | build
	rgbasm -o $@ b.asm

$(ROM_A): $(OBJ_A)
	rgblink -o $@ $<
	rgbfix $(RGBFIX_CARTUCHO) $@

$(ROM_B): $(OBJ_B)
	rgblink -o $@ $<
	rgbfix $(RGBFIX_CARTUCHO) $@

clean:
	rm -rf build
