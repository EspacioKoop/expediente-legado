from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "main.asm"
ROM = ROOT / "build" / "ariadne_98.gbc"


class AriadneSRAMTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def bloque(self, inicio, fin):
        return self.source.split(inicio, 1)[1].split(fin, 1)[0]

    def test_mejor_marca_usa_sram_local_sin_handshake_siga(self):
        for literal in (
            "DEF SRAM_MAGIC0           EQU $A000",
            "DEF SRAM_MEJOR_PASOS      EQU $A004",
            "DEF SRAM_CHECKSUM         EQU $A005",
            "call ActualizarMejorMarcaSRAM",
            "call HabilitarSRAM",
            "jp ProtegerSRAM",
            "xor $A7",
        ):
            self.assertIn(literal, self.source)
        self.assertNotIn("$C100", self.source)
        self.assertNotIn('SECTION "Handshake"', self.source)

    def test_solo_la_victoria_confirmada_puede_guardar_record(self):
        salida = self.bloque(".salida:", "IncrementarPasos:")
        self.assertIn("ld a, [wCentroAlcanzado]", salida)
        self.assertIn("ret z", salida)
        self.assertIn("call MostrarSalida", salida)

        mostrar = self.bloque("MostrarSalida:", "DibujarHUD:")
        self.assertLess(
            mostrar.index("call ActualizarMejorMarcaSRAM"),
            mostrar.index("call LimpiarFondo"),
        )

        arranque = self.bloque("IniciarJuego:", "; Cargar nivel")
        contacto = self.bloque("ComprobarContactoMinotauro:", "ReiniciarMinotauro:")
        self.assertNotIn("ActualizarMejorMarcaSRAM", arranque)
        self.assertNotIn("SRAM_", arranque)
        self.assertNotIn("ActualizarMejorMarcaSRAM", contacto)
        self.assertNotIn("SRAM_", contacto)

    def test_sram_corrupta_degrada_a_sin_marca_y_no_pisa_records_mejores(self):
        rutina = self.bloque("ActualizarMejorMarcaSRAM:", "HabilitarSRAM:")
        for literal in (
            "ld [wMejorPasos], a",
            "cp $41 ; A",
            "cp $52 ; R",
            "cp $49 ; I",
            "cp SRAM_VERSION_ACTUAL",
            "cp c",
            "jr nz, .comparar",
            "jr z, .proteger",
            "jr c, .proteger",
            "ld [SRAM_MEJOR_PASOS], a",
        ):
            self.assertIn(literal, rutina)

    def test_rom_compilada_es_dual_mode_y_tiene_titulo_propio(self):
        self.assertTrue(ROM.exists(), "falta compilar build/ariadne_98.gbc")
        data = ROM.read_bytes()
        self.assertGreaterEqual(len(data), 32768)
        self.assertEqual(data[0x134:0x143].rstrip(b"\0"), b"ARIADNE98")
        self.assertEqual(data[0x143], 0x80)


if __name__ == "__main__":
    unittest.main(verbosity=2)
