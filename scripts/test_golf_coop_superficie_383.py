import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ACCESO = ROOT / "godot" / "guion" / "golf_coop_acceso.gd"
PARTIDA = ROOT / "godot" / "guion" / "golf_partida_app.gd"
PRUEBA = "pruebas/pruebas_golf_coop_superficie_383.gd"
RESUMEN = re.compile(r"golf_coop_superficie_383: (\d+) pasadas, 0 fallos")


class GolfCoopSuperficie383Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.acceso = ACCESO.read_text(encoding="utf-8")
        cls.partida = PARTIDA.read_text(encoding="utf-8")

    def test_superficie_real_monta_acceso_opt_in(self):
        self.assertIn('preload("res://guion/golf_coop_acceso.gd")', self.partida)
        self.assertIn('coop_acceso.name = "GolfCoopAcceso"', self.partida)
        self.assertIn("coop_acceso.configurar(self, CONFIGURACIONES)", self.partida)

    def test_reutiliza_panel_servicio_autoridad_y_hoyo(self):
        for token in (
            "MinijuegoSalaPanel",
            "MinijuegoServicio",
            "MinijuegoGolfAutoridad",
            "GolfHoyoApp",
            "IdentidadOnline",
            "TransporteWebSocket",
        ):
            self.assertIn(token, self.acceso)
        self.assertNotIn("GolfBola.golpear(", self.acceso)
        self.assertNotIn("Golf.golpear(", self.acceso)
        self.assertNotIn("Partida", "\n".join(
            line for line in self.acceso.splitlines()
            if not line.lstrip().startswith("#")
        ))

    def test_online_es_opt_in_y_local_sigue_si_no_se_abre(self):
        self.assertIn("_abrir.pressed.connect(_abrir_panel)", self.acceso)
        self.assertIn("_activar.pressed.connect(_activar_online)", self.acceso)
        self.assertIn("_bloquear_golf_local(true)", self.acceso)
        self.assertIn("_bloquear_golf_local(false)", self.acceso)
        self.assertIn("_ocultar_golf_local(false)", self.acceso)

    def test_smoke_dos_clientes_hasta_resultado(self):
        importar_proyecto()
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--accessibility",
                "disabled",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=45,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
