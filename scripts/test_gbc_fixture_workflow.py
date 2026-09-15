from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "gbc-fixtures.yml"
CGB_ONLY_FIXTURE = ROOT / "gbc" / "fixtures" / "cgb_only_smoke" / "main.asm"


class GbcFixtureWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = WORKFLOW.read_text(encoding="utf-8")
        cls.cgb_only = CGB_ONLY_FIXTURE.read_text(encoding="utf-8")

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

    def test_compila_los_fixtures_cc0_minimos(self):
        self.assertIn("for fixture in joypad vblank", self.texto)
        self.assertIn("joypad.gb", self.texto)
        self.assertIn("vblank.gb", self.texto)
        self.assertNotIn("ucity.gbc", self.texto)
        self.assertNotIn("BIOS", self.texto)

    def test_cgb_acid2_esta_fijado_y_se_compila_desde_fuente(self):
        self.assertIn(
            "CGB_ACID2_COMMIT: fa5b7f86d6fb599f79e55169494d981a7af75a31",
            self.texto,
        )
        self.assertIn(
            "CGB_ACID2_MGBLIB_COMMIT: 5d829bf2ffa1447dcfd63c5dab2c44488632617e",
            self.texto,
        )
        self.assertIn("git -C cgb-acid2-src submodule update --init --depth 1 mgblib", self.texto)
        self.assertIn("cgb-acid2.gbc", self.texto)
        self.assertIn(
            'test "$(od -An -tx1 -j 323 -N 1 gbc-fixtures/cgb-acid2.gbc | tr -d \' \\n\')" = "c0"',
            self.texto,
        )

    def test_cgb_acid2_usa_toolchain_historico_aislado(self):
        self.assertIn(
            "CGB_ACID2_RGBDS_COMMIT: 0759c98d913e3d4d21207a8886a319c85add2041",
            self.texto,
        )
        self.assertIn('make -C rgbds-legacy-src CFLAGS="-g -fcommon"', self.texto)
        self.assertIn(
            'PATH="$GITHUB_WORKSPACE/rgbds-legacy-src:$PATH" make -C cgb-acid2-src all',
            self.texto,
        )
        self.assertIn("byacc flex pkg-config libpng-dev", self.texto)
        self.assertIn("make -C gbc/fixtures/cgb_only_smoke clean all", self.texto)

    def test_fixture_cgb_only_es_propio_y_se_compila_desde_fuente(self):
        self.assertIn("gbc/fixtures/cgb_only_smoke/**", self.texto)
        self.assertIn("make -C gbc/fixtures/cgb_only_smoke clean all", self.texto)
        self.assertIn("cgb_only_smoke.gbc", self.texto)
        self.assertIn('= "c0"', self.texto)
        self.assertIn("db $C0", self.cgb_only)
        self.assertIn("rBCPS", self.cgb_only)
        self.assertIn("rBCPD", self.cgb_only)

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
