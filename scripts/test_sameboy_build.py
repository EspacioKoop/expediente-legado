from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "godot" / "native" / "siga98_gb"
LOCK = NATIVE / "deps.lock.json"
SCONSTRUCT = NATIVE / "SConstruct"
PREPARE = ROOT / "scripts" / "preparar_emulador_gb.sh"
WRAPPER = NATIVE / "src" / "siga98_gb.cpp"


class SameBoyBuildGateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lock = json.loads(LOCK.read_text(encoding="utf-8"))
        cls.sconstruct = SCONSTRUCT.read_text(encoding="utf-8")
        cls.prepare = PREPARE.read_text(encoding="utf-8")
        cls.wrapper = WRAPPER.read_text(encoding="utf-8")

    def test_sameboy_esta_fijado_y_acotado_a_core(self):
        sameboy = self.lock["sameboy"]
        self.assertEqual(sameboy["repository"], "https://github.com/LIJI32/SameBoy.git")
        self.assertEqual(
            sameboy["commit"], "213a12ce93d66b105a113debd9396306066a7cfc"
        )
        self.assertEqual(sameboy["license"], "Expat")
        self.assertEqual(sameboy["scope"], "Core/")

    def test_preparador_descarga_exactamente_el_commit_fijado(self):
        self.assertIn("SAMEBOY_REPO=", self.prepare)
        self.assertIn("SAMEBOY_SHA=", self.prepare)
        self.assertIn('SAMEBOY="$DEPS/sameboy"', self.prepare)
        self.assertIn(
            'preparar_repo "$SAMEBOY_REPO" "$SAMEBOY_SHA" "$SAMEBOY" no',
            self.prepare,
        )
        self.assertIn('sameboy_dir="$SAMEBOY"', self.prepare)

    def test_sconstruct_compila_core_sin_frontends_ni_subsistemas_innecesarios(self):
        self.assertIn('os.path.join(sameboy_dir, "Core", "gb.h")', self.sconstruct)
        self.assertIn('os.path.join(sameboy_dir, "Core")', self.sconstruct)
        self.assertIn('filename.endswith(".c")', self.sconstruct)
        for source in (
            "debugger.c",
            "sm83_disassembler.c",
            "symbol_hash.c",
            "cheats.c",
            "cheat_search.c",
            "rewind.c",
        ):
            self.assertIn(f'"{source}"', self.sconstruct)
        for define in (
            "GB_INTERNAL",
            "GB_DISABLE_TIMEKEEPING",
            "GB_DISABLE_REWIND",
            "GB_DISABLE_DEBUGGER",
            "GB_DISABLE_CHEATS",
            "GB_DISABLE_CHEAT_SEARCH",
        ):
            self.assertIn(f'"{define}"', self.sconstruct)
        self.assertIn(r'-DGB_VERSION=\"1.0.3\"', self.sconstruct)
        self.assertIn("sameboy_env.SharedObject(sameboy_sources)", self.sconstruct)

    def test_stage_no_declara_capacidades_antes_del_adapter(self):
        self.assertIn('return "Peanut-GB";', self.wrapper)
        self.assertIn("bool Siga98GB::supports_cgb() const", self.wrapper)
        self.assertIn("bool Siga98GB::supports_audio() const", self.wrapper)
        self.assertNotIn('return "SameBoy";', self.wrapper)


if __name__ == "__main__":
    unittest.main()
