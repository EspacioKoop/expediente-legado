from pathlib import Path
import os
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
OBSERVER = ROOT / "godot" / "guion" / "religion_rom_vigilia.gd"
JALI = ROOT / "godot" / "guion" / "jali_98_vigilia.gd"
CONSUMER = ROOT / "godot" / "guion" / "religion_recuerdo_jali_932.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_jali_98_app.gd"
ROM = ROOT / "gbc" / "minijuegos" / "jali_98" / "main.asm"
README = ROOT / "gbc" / "minijuegos" / "jali_98" / "README.md"
DOC = ROOT / "docs" / "religion-rom-jali-932.md"
TEST_GODOT = "res://pruebas/pruebas_religion_rom_932.gd"


class ReligionRom932Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.observer = OBSERVER.read_text(encoding="utf-8")
        cls.jali = JALI.read_text(encoding="utf-8")
        cls.consumer = CONSUMER.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.rom = ROM.read_text(encoding="utf-8")
        cls.readme = README.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_observer_registra_solo_exposicion(self):
        self.assertIn("ReligionEventos.CANAL_EXPOSICION", self.observer)
        self.assertNotIn("CANAL_PRACTICA", self.observer)
        self.assertNotIn("CANAL_CONVICCION", self.observer)
        self.assertIn('const TRADICION := "islam"', self.jali)
        self.assertIn("mughal_india:agra:segunda_mitad_siglo_xvi", self.jali)

    def test_handshake_es_externo_y_determinista(self):
        self.assertIn("0xC100", self.jali)
        self.assertIn("0xA5", self.jali)
        self.assertIn('const TITULO_ROM := "JALI98"', self.jali)
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.rom)
        self.assertIn("DEF MARCA_COMPLETADO EQU $A5", self.rom)

    def test_consumidor_no_inventa_hechos_ni_conviccion(self):
        self.assertIn('"hechos_nuevos": false', self.consumer)
        self.assertIn('"asume_conviccion": false', self.consumer)
        self.assertIn('["geometria", "luz", "sombra", "calado"]', self.consumer)
        self.assertIn('set_meta("recuerdo_cultural_jali_98"', self.controller)

    def test_documentacion_separa_fuente_e_invencion(self):
        self.assertIn("1993.67.1", self.doc)
        self.assertIn("The Metropolitan Museum of Art", self.doc)
        self.assertIn("Invención del juego", self.doc)
        self.assertIn("No se reproduce", self.doc)
        self.assertIn("1993.67.1", self.readme)

    def test_vertical_no_incluye_linea_descartada(self):
        for text in (self.jali, self.consumer, self.controller, self.readme, self.doc):
            self.assertNotIn("hebre", text.lower())

    def test_godot_contract(self):
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="religion-rom-932-") as tmp:
            env = os.environ.copy()
            env["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                env[key] = str(Path(tmp) / key)
            result = subprocess.run(
                [
                    engine,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    TEST_GODOT,
                ],
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=240,
                check=False,
            )
            try:
                validar(result.stdout, result.returncode, 14, False)
            except ValueError as error:
                self.fail(f"{error}\n{result.stdout}")


if __name__ == "__main__":
    unittest.main()
