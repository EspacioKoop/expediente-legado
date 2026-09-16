import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
NAVEGACION = ROOT / "godot" / "guion" / "navegacion_oficina.gd"
RECADO = ROOT / "godot" / "guion" / "recado_companero_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_companeros_idle_app.gd"
PRUEBA_GODOT = "pruebas/pruebas_recados_oficina.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class RecadosOficinaTest(unittest.TestCase):
    def test_recados_no_tocan_estado_de_juego(self):
        texto = "".join(p.read_text(encoding="utf-8") for p in (NAVEGACION, RECADO, CONTROLLER))
        for termino in ("Jornada.", "Partida", "guardar(", "dinero", "Inventario"):
            self.assertNotIn(termino, texto)

    def test_sin_azar_ni_colision_propia(self):
        texto = RECADO.read_text(encoding="utf-8") + CONTROLLER.read_text(encoding="utf-8")
        for termino in ("randf", "randi", "CollisionShape3D", "CharacterBody3D"):
            self.assertNotIn(termino, texto)

    def test_malla_sale_de_los_colliders_del_espacio(self):
        texto = NAVEGACION.read_text(encoding="utf-8")
        self.assertIn("PARSED_GEOMETRY_STATIC_COLLIDERS", texto)
        self.assertIn("bake_from_source_geometry_data", texto)

    def test_recados_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=120,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIsNotNone(RESUMEN_GODOT.search(resultado.stdout), resultado.stdout)


if __name__ == "__main__":
    unittest.main()
