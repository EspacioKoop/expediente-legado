from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent
ROM = ROOT / "build" / "aquiles_98.gbc"
SOURCE = ROOT / "game.asm"


def main() -> None:
    if not ROM.exists():
        subprocess.run(["make"], cwd=ROOT, check=True)

    data = ROM.read_bytes()
    assert len(data) >= 32768, f"ROM demasiado pequena: {len(data)} bytes"
    assert data[0x134:0x143].rstrip(b"\0") == b"MYRMIDON98", data[0x134:0x143]
    assert data[0x143] == 0x80, f"flag CGB inesperado: {data[0x143]:#x}"

    source = SOURCE.read_text(encoding="utf-8")
    for invariant in (
        "LECTURA_COMPLETA EQU $0F",
        "and KEY_B",
        "ld [wMascaraLectura], a",
        "cp 2\n    jr nz, FallarGolpe",
        "cp 3\n    jr nz, FallarGolpe",
        "ld [wLeido], a\n    ld [wMascaraLectura], a",
        "IMPACTOS_META    EQU 3",
    ):
        assert invariant in source, f"falta invariante: {invariant!r}"

    print("MYRMIDON 98: cabecera y contrato de duelo OK")


if __name__ == "__main__":
    main()
