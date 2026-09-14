from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "gbc-fixtures.yml"


class GbcFixtureWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = WORKFLOW.read_text(encoding="utf-8")

    def test_upstream_y_toolchain_estan_fijados(self):
        self.assertIn("RGBDS_VERSION: v1.0.3", self.texto)
        self.assertIn(
            "RGBDS_SHA256: 280a52061a0c516999bee75ac357628d6d50784309e0486cef25f7460e6f330b",
            self.texto,
        )
        self.assertIn(
            "FIXTURES_COMMIT: 54270e0673ac16452447ff65cca26a1ef42eefec",
            self.texto,
        )
        self.assertIn("sha256sum --check --strict", self.texto)

    def test_solo_compila_los_dos_fixtures_cc0_iniciales(self):
        self.assertIn("for fixture in joypad vblank", self.texto)
        self.assertIn("joypad.gb", self.texto)
        self.assertIn("vblank.gb", self.texto)
        self.assertNotIn("ucity.gbc", self.texto)
        self.assertNotIn("BIOS", self.texto)

    def test_roms_no_se_versionan_y_solo_salen_como_artefacto_corto(self):
        self.assertIn("actions/upload-artifact@v4", self.texto)
        self.assertIn("retention-days: 7", self.texto)
        self.assertIn("SHA256SUMS", self.texto)
        self.assertNotIn("git add", self.texto)
        self.assertNotIn("git push", self.texto)

    def test_hay_comprobacion_minima_de_rom_generada(self):
        self.assertIn("test -s \"$rom\"", self.texto)
        self.assertIn("test \"$size\" -ge 32768", self.texto)


if __name__ == "__main__":
    unittest.main()
