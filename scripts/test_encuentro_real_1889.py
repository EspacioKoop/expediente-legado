import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ENCUENTRO = ROOT / "godot" / "guion" / "dia_encuentro_real_1889_app.gd"
CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
PRUEBA = "pruebas/pruebas_encuentro_real_1889.gd"
RESUMEN = re.compile(r"encuentro_real_1889: (\d+) pasadas, 0 fallos")


class EncuentroReal1889Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.encuentro = ENCUENTRO.read_text(encoding="utf-8")
        cls.calle = CALLE.read_text(encoding="utf-8")

    def test_calle_monta_un_unico_vertical_y_usa_la_frontera_existente(self):
        self.assertIn("DiaEncuentroReal1889App.new()", self.calle)
        self.assertIn("abrir_combate_real(objetivo)", self.calle)
        self.assertIn("combate_real_terminado.connect(", self.calle)
        self.assertNotIn("JuicioCombate3D.new()", self.calle)

    def test_encuentro_es_opt_in_y_no_crea_ataque_global(self):
        self.assertIn("extends Node3D", self.encuentro)
        self.assertIn("Interactuable3D.new()", self.encuentro)
        self.assertIn("combate_solicitado.emit(objetivo())", self.encuentro)
        self.assertRegex(self.encuentro, r"CombateContextual\s*\.\s*autorizar_realidad\(")
        self.assertNotIn("Input.is_action", self.encuentro)
        self.assertNotIn("IncidentesConducta.GOLPE_PARED", self.encuentro)

    def test_consecuencia_es_acotada_e_idempotente(self):
        self.assertIn('const CLAVE_ESTADO := "encuentro_real_1889"', self.encuentro)
        self.assertIn('const TIPO_CONSECUENCIA := "cerrar_incidente_callejero"', self.encuentro)
        self.assertIn("if resuelto():", self.encuentro)
        self.assertNotIn("dinero", self.encuentro)
        self.assertNotIn("momentum", self.encuentro)

    def test_smoke_headless(self):
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
        self.assertGreaterEqual(int(resumen.group(1)), 14, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
