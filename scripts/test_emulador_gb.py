from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "godot" / "native" / "siga98_gb"
UI = ROOT / "godot" / "guion" / "emulador_portatil_app.gd"
PORTATIL = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
EXTENSION = ROOT / "godot" / "addons" / "siga98_gb" / "siga98_gb.gdextension"
LOCK = NATIVE / "deps.lock.json"
CI = ROOT / ".github" / "workflows" / "ci.yml"
ALPHA = ROOT / ".github" / "workflows" / "alpha-playtest.yml"


class EmuladorGBTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cpp = (NATIVE / "src" / "siga98_gb.cpp").read_text(encoding="utf-8")
        cls.ui = UI.read_text(encoding="utf-8")
        cls.portatil = PORTATIL.read_text(encoding="utf-8")
        cls.extension = EXTENSION.read_text(encoding="utf-8")
        cls.lock = json.loads(LOCK.read_text(encoding="utf-8"))
        cls.ci = CI.read_text(encoding="utf-8")
        cls.alpha = ALPHA.read_text(encoding="utf-8")

    def test_dependencias_estan_fijadas_y_son_mit(self):
        self.assertEqual(
            self.lock["godot_cpp"]["commit"],
            "6cceaf6a5f8b0d78ac5d71c139fd7fabba43b918",
        )
        self.assertEqual(
            self.lock["peanut_gb"]["commit"],
            "8e656982f08663785794b84823d3e27f856fdb7f",
        )
        self.assertEqual(self.lock["godot_cpp"]["license"], "MIT")
        self.assertEqual(self.lock["peanut_gb"]["license"], "MIT")

    def test_nucleo_rechaza_cgb_only_y_acota_roms(self):
        self.assertIn("CGB_ONLY_FLAG = 0xC0", self.cpp)
        self.assertIn("LOAD_CGB_ONLY", self.cpp)
        self.assertIn("MIN_ROM_SIZE = 32 * 1024", self.cpp)
        self.assertIn("MAX_ROM_SIZE = 8 * 1024 * 1024", self.cpp)

    def test_framebuffer_y_joypad_tienen_contrato_minimo(self):
        self.assertIn("FRAME_WIDTH = 160", self.cpp)
        self.assertIn("FRAME_HEIGHT = 144", self.cpp)
        self.assertIn("gb_run_frame", self.cpp)
        self.assertIn("direct.joypad", self.cpp)
        self.assertIn("run_frame_rgba", self.cpp)

    def test_portatil_abre_ui_sin_estado_de_campana(self):
        self.assertIn("EmuladorPortatilApp.new()", self.portatil)
        combinado = self.cpp + self.ui + self.portatil
        for termino in ("Partida", "Jornada", "pistas_descubiertas", "dinero"):
            self.assertNotIn(termino, combinado)

    def test_ui_usa_rom_propia_y_catalogo_usuario(self):
        self.assertIn('ROM_PROPIA := "res://roms/caza_pixeles_98.gbc"', self.ui)
        self.assertIn("CatalogoRomsUsuario.listar()", self.ui)
        self.assertIn('ClassDB.class_exists(&"Siga98GB")', self.ui)
        self.assertIn("JOY_BUTTON_DPAD_RIGHT", self.ui)

    def test_extension_declara_linux_y_windows(self):
        self.assertIn('compatibility_minimum = "4.7"', self.extension)
        self.assertIn("linux.x86_64.single.debug", self.extension)
        self.assertIn("linux.x86_64.single.release", self.extension)
        self.assertIn("windows.x86_64.single.release", self.extension)

    def test_ci_no_lintea_dependencias_descargadas(self):
        self.assertIn("-not -path 'godot/native/siga98_gb/.deps/*'", self.ci)
        self.assertNotIn("gdlint godot\n", self.ci)

    def test_alpha_importa_antes_del_smoke(self):
        importar = "godot4 --headless --editor --path godot --quit"
        smoke = "godot4 --headless --path godot --script res://pruebas/emulador_gb_smoke.gd"
        self.assertIn(importar, self.alpha)
        self.assertIn(smoke, self.alpha)
        self.assertLess(self.alpha.index(importar), self.alpha.index(smoke))


if __name__ == "__main__":
    unittest.main()
