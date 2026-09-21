from pathlib import Path
import os
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
OBSERVER = ROOT / "godot" / "guion" / "religion_rom_vigilia.gd"
JALI = ROOT / "godot" / "guion" / "jali_98_vigilia.gd"
VITRAL = ROOT / "godot" / "guion" / "vitral_98_vigilia.gd"
VITRAL_CONTROLLER = ROOT / "godot" / "guion" / "dia_vitral_98_app.gd"
VITRAL_ROM = ROOT / "gbc" / "minijuegos" / "vitral_98" / "main.asm"
VITRAL_DOC = ROOT / "docs" / "religion-rom-vitral-932.md"
SARNATH = ROOT / "godot" / "guion" / "sarnath_98_vigilia.gd"
SARNATH_CONTROLLER = ROOT / "godot" / "guion" / "dia_sarnath_98_app.gd"
SARNATH_ROM = ROOT / "gbc" / "minijuegos" / "sarnath_98" / "main.asm"
SARNATH_DOC = ROOT / "docs" / "religion-rom-sarnath-932.md"
CONSUMER = ROOT / "godot" / "guion" / "religion_recuerdo_jali_932.gd"
CONSUMER_3D = ROOT / "godot" / "guion" / "religion_recuerdo_jali_932_3d.gd"
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
        cls.vitral = VITRAL.read_text(encoding="utf-8")
        cls.vitral_controller = VITRAL_CONTROLLER.read_text(encoding="utf-8")
        cls.vitral_rom = VITRAL_ROM.read_text(encoding="utf-8")
        cls.vitral_doc = VITRAL_DOC.read_text(encoding="utf-8")
        cls.sarnath = SARNATH.read_text(encoding="utf-8")
        cls.sarnath_controller = SARNATH_CONTROLLER.read_text(encoding="utf-8")
        cls.sarnath_rom = SARNATH_ROM.read_text(encoding="utf-8")
        cls.sarnath_doc = SARNATH_DOC.read_text(encoding="utf-8")
        cls.consumer = CONSUMER.read_text(encoding="utf-8")
        cls.consumer_3d = CONSUMER_3D.read_text(encoding="utf-8")
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

    def test_segunda_rom_reutiliza_observer_comun(self):
        self.assertIn('extends "res://guion/religion_rom_vigilia.gd"', self.vitral)
        self.assertIn('const TRADICION := "cristianismo"', self.vitral)
        self.assertIn("europa_cristiana:vidriera_taller:ca_1375", self.vitral)
        self.assertIn('const TITULO_ROM := "VITRAL98"', self.vitral)
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.vitral_rom)
        self.assertIn("Vitral98Vigilia.new()", self.vitral_controller)
        self.assertIn("V&A", self.vitral_doc)
        self.assertIn("No se reconstruye el panel de Erfurt", self.vitral_doc)

    def test_tercera_rom_cambia_mecanica_sin_cambiar_contrato(self):
        self.assertIn('extends "res://guion/religion_rom_vigilia.gd"', self.sarnath)
        self.assertIn('const TRADICION := "budismo"', self.sarnath)
        self.assertIn("india:varanasi:sarnath:sitio_arqueologico:unesco_2026", self.sarnath)
        self.assertIn('const TITULO_ROM := "SARNATH98"', self.sarnath)
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.sarnath_rom)
        self.assertIn("Ruta0:", self.sarnath_rom)
        self.assertIn("Sarnath98Vigilia.new()", self.sarnath_controller)
        self.assertIn("UNESCO", self.sarnath_doc)
        self.assertIn("no reproduce el trazado de Sarnath", self.sarnath_doc)

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

    def test_consecuencia_posterior_es_visible_y_no_jugable(self):
        self.assertIn("class_name ReligionRecuerdoJali9323D", self.consumer_3d)
        self.assertIn("for indice in 3", self.consumer_3d)
        self.assertIn("for brazo in 4", self.consumer_3d)
        self.assertNotIn("CollisionShape3D", self.consumer_3d)
        self.assertIn('== "sueño"', self.controller)
        self.assertIn("ReligionRecuerdoJali9323D.montar", self.controller)

    def test_documentacion_separa_fuente_e_invencion(self):
        self.assertIn("1993.67.1", self.doc)
        self.assertIn("The Metropolitan Museum of Art", self.doc)
        self.assertIn("Invención del juego", self.doc)
        self.assertIn("No se reproduce", self.doc)
        self.assertIn("1993.67.1", self.readme)

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
