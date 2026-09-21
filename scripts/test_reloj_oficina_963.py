import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RELOJ = ROOT / "godot" / "guion" / "reloj_oficina_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_reloj_horario_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class RelojOficina963Test(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_reloj_oficina_963.gd",
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
        self.assertGreaterEqual(int(resumen.group(1)), 12, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_el_controller_cuelga_del_dia_real(self):
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('res://guion/dia_reloj_horario_app.gd', escena)
        self.assertIn('name="RelojHorarioController"', escena.replace(" ", ""))

    def test_jornada_es_la_unica_fuente_de_hora(self):
        controlador = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn("Jornada.hora_minutos(dia.jornada)", controlador)
        self.assertNotIn("avanzar_reloj", controlador)
        self.assertNotIn('["hora_minutos"] =', controlador)
        self.assertNotIn("Time.get_", controlador)
        self.assertNotIn("Timer.new()", controlador)

    def test_el_reloj_no_tiene_un_tick_propio(self):
        reloj = RELOJ.read_text(encoding="utf-8")
        self.assertIn("func poner_hora(minutos: int)", reloj)
        self.assertNotIn("func _process", reloj)
        self.assertNotIn("Timer.new()", reloj)
        self.assertNotIn("Time.get_", reloj)


if __name__ == "__main__":
    unittest.main()
