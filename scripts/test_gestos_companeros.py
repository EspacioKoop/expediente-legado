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
        idle = IDLE.read_text(encoding="utf-8")
        controller = CONTROLLER.read_text(encoding="utf-8")
        texto = idle + controller
        for termino in ("Partida", "guardar(", "dinero", "acciones"):
            self.assertNotIn(termino, texto)

        # #963 puede hacer únicamente lecturas canónicas de Jornada para
        # densidad ambiental y disponibilidad de servicios. El gesto visual
        # puro sigue sin depender de Jornada y el controller no puede mutarla.
        self.assertNotIn("Jornada.", idle)
        usos_jornada = re.findall(r"Jornada\.([A-Za-z_][A-Za-z0-9_]*)\s*\(", controller)
        self.assertGreater(len(usos_jornada), 0)
        self.assertEqual({"franja_horaria", "servicio_disponible"}, set(usos_jornada))
        for escritura in ("gastar", "avanzar", "consumir", "registrar"):
            self.assertNotIn(f"Jornada.{escritura}(", controller)

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
