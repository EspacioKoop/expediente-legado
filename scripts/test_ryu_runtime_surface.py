import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
INDICE = ROOT / "godot" / "datos" / "roms_propias.json"
CONSOLA = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
DOCS = ROOT / "docs" / "roms-propias.md"


class RyuRuntimeSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        datos = json.loads(INDICE.read_text(encoding="utf-8"))
        cls.ryu = next(rom for rom in datos["roms"] if rom["id"] == "ryu_flow_98")
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.docs = DOCS.read_text(encoding="utf-8")

    def test_ryu_flow_entra_en_build_y_consola_sin_compra(self):
        self.assertEqual(self.ryu["estado"], "jugable")
        self.assertEqual(self.ryu["rom"], "res://roms/ryu_flow_98.gbc")
        self.assertEqual(self.ryu["cabecera"], "RYUFLOW98")
        self.assertEqual(self.ryu["cgb"], "dual")
        self.assertTrue(self.ryu["incluida"])
        self.assertEqual(self.ryu["precio"], 0)

    def test_consola_expone_titulo_y_lectura_genericos(self):
        self.assertIn("func titulo_rom_activa() -> String:", self.consola)
        self.assertIn("func leer_memoria_rom_u8(direccion: int) -> int:", self.consola)
        self.assertIn('emulador.call("rom_title")', self.consola)
        self.assertIn('emulador.call("read_memory_u8", direccion)', self.consola)
        self.assertIn("return -1", self.consola)

    def test_superficie_generica_no_conoce_handshake_ryu(self):
        for termino in (
            "RYUFLOW98",
            "ryu_flow_98",
            "semilla_onirica_ryu",
            "0xC100",
            "0xA5",
            "SemillasOniricas",
        ):
            self.assertNotIn(termino, self.consola)

    def test_documentacion_refleja_promocion_y_handshake_pendiente(self):
        self.assertIn("| `ryu_flow_98` | RYU FLOW |", self.docs)
        self.assertIn("incluida con la consola", self.docs)
        self.assertIn("`0xA5` en WRAM `$C100`", self.docs)
        self.assertIn("una capa de gameplay debe traducir el handshake", self.docs)


if __name__ == "__main__":
    unittest.main()
