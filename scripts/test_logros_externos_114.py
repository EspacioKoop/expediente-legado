from pathlib import Path
import re
import unittest

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT / "godot/guion/logros_backend.gd"
NULO = ROOT / "godot/guion/logros_backend_nulo.gd"
SYNC = ROOT / "godot/guion/logros_externos.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class LogrosExternos114Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend = BACKEND.read_text(encoding="utf-8")
        cls.nulo = NULO.read_text(encoding="utf-8")
        cls.sync = SYNC.read_text(encoding="utf-8")

    def test_backend_es_agnostico_de_steam(self):
        self.assertIn("class_name LogrosBackend", self.backend)
        self.assertIn("class_name LogrosBackendNulo", self.nulo)
        combinado = self.backend + self.nulo + self.sync
        self.assertNotIn("Steam.", combinado)
        self.assertNotIn("GodotSteam", combinado)
        self.assertNotIn("Steamworks", combinado)

    def test_prometeo_sigue_siendo_fuente_de_verdad(self):
        self.assertIn('estado.get("logros", [])', self.sync)
        self.assertIn('logro.get("desbloqueado", false)', self.sync)
        self.assertNotIn('estado["logros"] =', self.sync)
        self.assertNotIn("Partida.new()", self.sync)

    def test_sync_es_idempotente_y_guarda_solo_si_hay_novedades(self):
        self.assertIn("backend.esta_desbloqueado(logro_id)", self.sync)
        self.assertIn("backend.desbloquear(logro_id)", self.sync)
        self.assertIn('if not resultado["publicados"].is_empty():', self.sync)
        self.assertIn('resultado["guardado"] = backend.guardar()', self.sync)

    def test_runtime_con_backend_nulo_y_falso(self):
        resultado = ejecutar_script("pruebas/pruebas_logros_externos_114.gd")
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 12, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
