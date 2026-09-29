import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "incidente_impresora_oficina.gd"
PRUEBA = "res://pruebas/pruebas_incidente_impresora_1768.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class IncidenteImpresora1768Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = MODELO.read_text(encoding="utf-8")

    def test_secuencia_y_evento_canonicos(self):
        self.assertIn('EVENTO := "impresora_atascada"', self.fuente)
        for accion in (
            "inspeccionar",
            "abrir_bandeja",
            "retirar_papel",
            "cerrar_bandeja",
        ):
            self.assertIn(f'"{accion}"', self.fuente)
        self.assertIn('Azar.derivar(raiz, "dia"', self.fuente)

    def test_no_gasta_jornada_ni_inventa_economia(self):
        for llamada in (
            "Jornada.gastar",
            "Jornada.avanzar",
            "Jornada.consumir",
            "Jornada.pagar",
        ):
            self.assertNotIn(llamada, self.fuente)
        for campo in ("dinero", "nomina", "precio", "recompensa"):
            self.assertNotIn(campo, self.fuente.lower())
        self.assertNotRegex(self.fuente, r'jornada\s*\[[^\]]+\]\s*=')

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
