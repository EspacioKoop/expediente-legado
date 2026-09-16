import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
IDLE = ROOT / "godot" / "guion" / "companero_idle_3d.gd"
CATALOGO = ROOT / "godot" / "guion" / "espacios_catalogo.gd"
PRUEBA_GODOT = "pruebas/pruebas_companeros_sentados.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CompanerosSentadosTest(unittest.TestCase):
    def test_sillas_a_escala_de_persona_sentada(self):
        texto = CATALOGO.read_text(encoding="utf-8")
        self.assertNotIn("Vector3(0.62, 0.95, 0.62)", texto)
        self.assertIn("Vector3(0.74, 1.14, 0.74)", texto)

    def test_sentado_no_toca_estado_de_juego(self):
        texto = IDLE.read_text(encoding="utf-8")
        for termino in ("Jornada.", "Partida", "guardar(", "CollisionShape3D"):
            self.assertNotIn(termino, texto)

    def test_sentados_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIsNotNone(RESUMEN_GODOT.search(resultado.stdout), resultado.stdout)


if __name__ == "__main__":
    unittest.main()
