from __future__ import annotations

import hashlib
import tempfile
import unittest
from pathlib import Path

from scripts.inspect_gb_rom import inspect_rom


def make_rom(
    *,
    cgb_flag: int = 0xC0,
    cartridge_type: int = 0x1B,
    rom_size_code: int = 0x00,
    ram_size_code: int = 0x04,
) -> bytes:
    data = bytearray(32 * 1024)
    data[0x134:0x13D] = b"SIGA98ROM"
    data[0x143] = cgb_flag
    data[0x146] = 0x00
    data[0x147] = cartridge_type
    data[0x148] = rom_size_code
    data[0x149] = ram_size_code

    checksum = 0
    for value in data[0x134:0x14D]:
        checksum = (checksum - value - 1) & 0xFF
    data[0x14D] = checksum
    return bytes(data)


class InspectGbRomTest(unittest.TestCase):
    def test_extrae_contrato_estable_de_rom_cgb(self):
        rom = make_rom()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "fixture.gbc"
            path.write_bytes(rom)

            metadata = inspect_rom(path)

        self.assertEqual(metadata["sha256"], hashlib.sha256(rom).hexdigest())
        self.assertEqual(metadata["file_size_bytes"], 32768)
        self.assertEqual(metadata["title"], "SIGA98ROM")
        self.assertEqual(metadata["platform"], "GBC")
        self.assertEqual(metadata["cgb_mode"], "cgb_only")
        self.assertEqual(metadata["cgb_flag"], "0xC0")
        self.assertEqual(metadata["cartridge_type"], "0x1B")
        self.assertEqual(metadata["cartridge_type_name"], "MBC5+RAM+BATTERY")
        self.assertEqual(metadata["rom_size_bytes"], 32768)
        self.assertEqual(metadata["ram_size_bytes"], 128 * 1024)
        self.assertTrue(metadata["header_checksum_valid"])

    def test_distingue_dmg_y_cgb_compatible(self):
        with tempfile.TemporaryDirectory() as tmp:
            dmg = Path(tmp) / "dmg.gb"
            compat = Path(tmp) / "compat.gbc"
            dmg.write_bytes(make_rom(cgb_flag=0x00, cartridge_type=0x00, ram_size_code=0x00))
            compat.write_bytes(make_rom(cgb_flag=0x80, cartridge_type=0x00, ram_size_code=0x00))

            dmg_metadata = inspect_rom(dmg)
            compat_metadata = inspect_rom(compat)

        self.assertEqual(dmg_metadata["platform"], "GB")
        self.assertEqual(dmg_metadata["cgb_mode"], "dmg")
        self.assertEqual(compat_metadata["platform"], "GBC")
        self.assertEqual(compat_metadata["cgb_mode"], "cgb_compatible")

    def test_falla_si_sha256_no_coincide(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "fixture.gb"
            path.write_bytes(make_rom())

            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                inspect_rom(path, "0" * 64)

    def test_rechaza_archivo_demasiado_pequeno(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "truncated.gb"
            path.write_bytes(b"\0" * 32)

            with self.assertRaisesRegex(ValueError, "too small"):
                inspect_rom(path)


if __name__ == "__main__":
    unittest.main()
