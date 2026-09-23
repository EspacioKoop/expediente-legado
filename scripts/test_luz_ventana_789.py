"""La ventana del archivo (#789).

La jornada empieza a las nueve y el cristal era un azul de noche fijo, sin luz
que entrara por él. El contrato real se ejecuta en Godot; aquí se fija además
de dónde sale la hora: el módulo que construye el sitio no la sabe, así que el
foco nace apagado y solo lo gobierna quien lee `Jornada`.
"""

import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_reloj_horario_app.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_luz_ventana_789.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class LuzVentana789Test(unittest.TestCase):
    def test_el_constructor_no_decide_la_hora(self):
        espacio = ESPACIO.read_text(encoding="utf-8")
        self.assertNotIn("Jornada.", espacio)
        self.assertNotIn("perfil_luz(", espacio)

    def test_la_hora_de_la_ventana_sale_de_jornada(self):
        controlador = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn("Espacio3D.NOMBRE_CRISTAL_VENTANA", controlador)
        self.assertIn("Espacio3D.NOMBRE_LUZ_VENTANA", controlador)
        self.assertIn("Jornada.hora_minutos(dia.jornada)", controlador)

    def test_contrato_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=90,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
