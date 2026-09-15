from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CPP = ROOT / "godot" / "native" / "siga98_gb" / "src" / "siga98_gb.cpp"
HEADER = ROOT / "godot" / "native" / "siga98_gb" / "src" / "siga98_gb.h"
SMOKE = ROOT / "godot" / "pruebas" / "emulador_gb_smoke.gd"


class EmuladorGbMemoryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cpp = CPP.read_text(encoding="utf-8")
        cls.header = HEADER.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_api_publica_expone_un_byte_por_direccion(self):
        self.assertIn("int read_memory_u8(int64_t p_address) const;", self.header)
        self.assertIn('D_METHOD("read_memory_u8", "address")', self.cpp)
        self.assertIn("&Siga98GB::read_memory_u8", self.cpp)

    def test_lectura_es_segura_y_sin_efectos_laterales(self):
        bloque = self.cpp.split("int Siga98GB::read_memory_u8", 1)[1]
        bloque = bloque.split("String Siga98GB::rom_title", 1)[0]
        self.assertIn("GB_safe_read_memory", bloque)
        self.assertNotIn("GB_read_memory(", bloque)
        self.assertIn("p_address < 0", bloque)
        self.assertIn("p_address > 0xFFFF", bloque)
        self.assertIn("return -1;", bloque)

    def test_no_hay_lectura_si_el_core_no_esta_cargado(self):
        bloque = self.cpp.split("int Siga98GB::read_memory_u8", 1)[1]
        bloque = bloque.split("String Siga98GB::rom_title", 1)[0]
        self.assertIn("!impl->loaded", bloque)
        self.assertIn("impl->gb == nullptr", bloque)

    def test_smoke_cubre_sin_rom_rango_y_wram(self):
        self.assertIn("_probar_lectura_memoria_sin_rom(emulador)", self.smoke)
        self.assertIn("_probar_lectura_memoria_cargada(emulador)", self.smoke)
        self.assertIn('read_memory_u8", -1', self.smoke)
        self.assertIn('read_memory_u8", 0x10000', self.smoke)
        self.assertIn('read_memory_u8", 0xC000', self.smoke)

    def test_core_no_conoce_ryu_ni_semillas(self):
        bloque = self.cpp.split("int Siga98GB::read_memory_u8", 1)[1]
        bloque = bloque.split("String Siga98GB::rom_title", 1)[0].lower()
        self.assertNotIn("ryu", bloque)
        self.assertNotIn("semilla", bloque)
        self.assertNotIn("0xc100", bloque)
        self.assertNotIn("0xa5", bloque)


if __name__ == "__main__":
    unittest.main()
