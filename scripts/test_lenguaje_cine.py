"""Lenguaje de cine común del reproductor de cinemáticas (#395)."""

import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


RAIZ = Path(__file__).resolve().parents[1]
REPRODUCTOR = (RAIZ / "godot/guion/cinematica_app.gd").read_text(encoding="utf-8")
LENGUAJE = (RAIZ / "godot/guion/lenguaje_cine.gd").read_text(encoding="utf-8")
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class LenguajeCineTest(unittest.TestCase):
    def test_el_reproductor_usa_el_lenguaje_comun(self):
        for contrato in (
            "LenguajeCine.apertura_franjas(",
            "LenguajeCine.mano(_reloj, _reduccion_movimiento)",
            "LenguajeCine.fov_de(plano)",
            "LenguajeCine.atributos(",
            'preload("res://arte/grano_cine.gdshader")',
        ):
            with self.subTest(contrato=contrato):
                self.assertIn(contrato, REPRODUCTOR)

    def test_la_reduccion_de_movimiento_quita_mano_y_animacion(self):
        self.assertIn("if reducir:\n\t\treturn Vector3.ZERO", LENGUAJE)
        self.assertIn("if reducir:\n\t\treturn 1.0", LENGUAJE)
        self.assertIn('set_shader_parameter("quieto", _reduccion_movimiento)', REPRODUCTOR)

    def test_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(RAIZ / "godot"), "--script",
             "pruebas/pruebas_lenguaje_cine.gd"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120, check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIsNotNone(RESUMEN.search(resultado.stdout), resultado.stdout)


if __name__ == "__main__":
    unittest.main()
