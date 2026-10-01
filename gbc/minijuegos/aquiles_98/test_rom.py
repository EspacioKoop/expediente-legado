from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent
ROM = ROOT / "build" / "aquiles_98.gbc"
SOURCE = ROOT / "game.asm"
SYMBOLS = ROOT / "build" / "aquiles_98.sym"


def main() -> None:
    if not ROM.exists():
        subprocess.run(["make"], cwd=ROOT, check=True)

    data = ROM.read_bytes()
    assert len(data) >= 32768, f"ROM demasiado pequena: {len(data)} bytes"
    assert data[0x134:0x143].rstrip(b"\0") == b"MYRMIDON98", data[0x134:0x143]
    assert data[0x143] == 0x80, f"flag CGB inesperado: {data[0x143]:#x}"

    source = SOURCE.read_text(encoding="utf-8")
    symbols = {}
    for line in SYMBOLS.read_text(encoding="utf-8").splitlines():
        if line and not line.startswith(";"):
            address, name = line.split()
            symbols[name] = int(address.split(":")[1], 16)

    assert symbols["wEstado"] == 0xC000, hex(symbols["wEstado"])

    for invariant in (
        "LECTURA_COMPLETA EQU $0F",
        "and KEY_B",
        "ld [wMascaraLectura], a",
        "cp 2\n    jr nz, FallarGolpe",
        "cp 3\n    jr nz, FallarGolpe",
        "ld [wLeido], a\n    ld [wMascaraLectura], a",
        "IMPACTOS_META    EQU 3",
        "ESTADO_INTERLUDIO EQU 3",
        "PatronesGuardia:",
        "db 0, 1, 2, 3",
        "db 2, 0, 1, 3",
        "db 1, 2, 0, 3",
        "ld a, [wRival]\n    sla a\n    sla a",
        "ld a, [wRival]\n    or a\n    jr z, .lenta",
        "ld a, 36",
        "ld a, 28",
        "ld hl, wRival\n    inc [hl]\n    call MostrarInterludio",
        "cp IMPACTOS_META\n    jr nc, MostrarVictoria",
        'INCLUDE "assets/myrmidon_v1_tiles.inc"',
        "ld hl, MyrmidonBgTiles",
        "ld bc, MyrmidonHudBase - MyrmidonBgTiles",
        "ld hl, MyrmidonHudBase",
        "ld bc, MyrmidonHudRevealed - MyrmidonHudBase",
        "ld a, TILE_MYRMIDON_OBSERVAR",
        "ld a, TILE_MYRMIDON_REFLEJO",
        "ld a, TILE_MYRMIDON_COLUMNA",
        "ld a, TILE_MYRMIDON_ESTANDARTE",
        "ld a, TILE_MYRMIDON_SUELO",
    ):
        assert invariant in source, f"falta invariante: {invariant!r}"

    # El primer consumidor del pack usa exclusivamente bancos base. La
    # vulnerabilidad sigue bajo la regla previa de wLeido/fase 3.
    assert "MyrmidonFrameMapsRevealed" not in source
    assert "MyrmidonFrame_Vulnerable" not in source
    assert "MyrmidonHud_talon" not in source
    assert "TILE_CABEZA_2" in source and "TILE_CABEZA_3" in source

    assert symbols["wRival"] > symbols["wEstado"]
    assert symbols["wPasoPatron"] > symbols["wRival"]

    print("MYRMIDON 98: ABI, tres rivales y patrones de guardia OK")


if __name__ == "__main__":
    main()
