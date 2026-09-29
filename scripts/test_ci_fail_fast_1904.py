from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CI = (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
CHECK = (ROOT / "scripts" / "check_gdscript.sh").read_text(encoding="utf-8")


class CiFailFast1904Test(unittest.TestCase):
    def test_gdscript_rapido_ocurre_antes_de_toolchains_pesados(self):
        fast = CI.index("- name: Preflight GDScript fail-fast")
        lfs = CI.index("- name: Materializar LFS para CI completo")
        rgbds = CI.index("- name: Instalar RGBDS fijado")
        godot = CI.index("- name: Instalar el motor declarado por el proyecto")
        full = CI.index("- name: Preflight GDScript canónico")

        self.assertLess(fast, lfs)
        self.assertLess(fast, rgbds)
        self.assertLess(fast, godot)
        self.assertLess(godot, full)

    def test_fail_fast_usa_mismo_script_canonico_sin_ejecutar_suite(self):
        block = CI.split("- name: Preflight GDScript fail-fast", 1)[1].split(
            "- name: Preflight infra rápido", 1
        )[0]
        self.assertIn("SIGA98_GDSCRIPT_FAST: '1'", block)
        self.assertIn("bash scripts/check_gdscript.sh", block)
        self.assertIn('if [[ "${SIGA98_GDSCRIPT_FAST:-0}" == "1" ]]', CHECK)

        fast_guard = CHECK.index('if [[ "${SIGA98_GDSCRIPT_FAST:-0}" == "1" ]]')
        unittest_run = CHECK.index("-m unittest discover")
        self.assertLess(fast_guard, unittest_run)

    def test_preflight_completo_sigue_exigiendo_extension(self):
        full = CI.split("- name: Preflight GDScript canónico", 1)[1]
        self.assertIn("SIGA98_EXIGIR_EXTENSION: '1'", full)
        self.assertIn("run: bash scripts/check_gdscript.sh", full)


if __name__ == "__main__":
    unittest.main()
