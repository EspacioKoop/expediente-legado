import json
import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CONTRATO = ROOT / "godot" / "guion" / "red" / "meta_hastur_datos.gd"
FIXTURES = ROOT / "godot" / "datos" / "meta_hastur_fixtures.json"
SMOKE = "pruebas/pruebas_meta_hastur_382.gd"


class MetaHastur382Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contrato = CONTRATO.read_text(encoding="utf-8")
        cls.fixtures = json.loads(FIXTURES.read_text(encoding="utf-8"))

    def test_fixtures_cubren_cero_umbral_y_completo(self):
        snapshots = self.fixtures["snapshots"]
        self.assertEqual(snapshots["cero"]["community_progress"], 0)
        self.assertEqual(snapshots["primer_umbral"]["community_progress"], 25)
        self.assertEqual(snapshots["completo"]["community_progress"], 100)
        self.assertEqual(snapshots["completo"]["phase"], "derrota")

    def test_feature_gate_de_produccion_permanece_apagado(self):
        self.assertIn("const PRODUCCION_HABILITADA := false", self.contrato)
        self.assertIn('config.get("global_hastur_event", false)', self.contrato)
        self.assertIn("and version_1_0", self.contrato)

    def test_cliente_no_puede_enviar_puntos(self):
        self.assertNotIn('"progress",\n]', self.contrato)
        self.assertIn("CAMPOS_CONTRIBUCION", self.contrato)
        self.assertIn('return _invalido("unexpected_%s" % String(clave))', self.contrato)
        self.assertIn("PESOS_FIXTURE", self.contrato)

    def test_contrato_no_toca_partida_ni_red_real(self):
        combinado = self.contrato + FIXTURES.read_text(encoding="utf-8")
        self.assertNotIn("Partida", combinado)
        self.assertNotIn("HTTPClient", combinado)
        self.assertNotIn("WebSocketPeer", combinado)
        self.assertNotIn("FileAccess.open", self.contrato)

    def test_smoke_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                SMOKE,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("meta_hastur_382:", resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
