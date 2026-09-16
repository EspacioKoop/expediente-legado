import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
IDLE = ROOT / "godot" / "guion" / "companero_idle_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_companeros_idle_app.gd"
ANIMACIONES = ROOT / "godot" / "guion" / "animaciones_ual.gd"
PRUEBA_GODOT = "pruebas/pruebas_gestos_companeros.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class GestosCompanerosTest(unittest.TestCase):
    def test_gestos_no_tocan_estado_de_juego(self):
        texto = IDLE.read_text(encoding="utf-8") + CONTROLLER.read_text(encoding="utf-8")
        for termino in ("Jornada.", "Partida", "guardar(", "dinero", "acciones"):
            self.assertNotIn(termino, texto)

    def test_consume_no_se_ofrece_como_cafe(self):
        # En captura el clip Consume de UAL extiende el brazo al frente: no se
        # lee como tomar café y no debe volver al catálogo con ese nombre.
        self.assertNotIn('"cafe"', ANIMACIONES.read_text(encoding="utf-8"))

    def test_gestos_en_godot_headless(self):
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
