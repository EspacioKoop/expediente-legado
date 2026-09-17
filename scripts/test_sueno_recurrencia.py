import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
RECURRENCIA = ROOT / "godot" / "guion" / "sueno_recurrencia_simbolica.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
PRUEBA_GODOT = "pruebas/pruebas_sueno_recurrencia.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoRecurrenciaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.recurrencia = RECURRENCIA.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")

    def test_controller_deriva_fase_de_la_secuencia_existente(self):
        self.assertIn("MitologiasNoche.indice_escena_actual", self.controlador)
        self.assertRegex(self.controlador, r"SuenoRecurrenciaSimbolica\s*\.\s*montar\(")
        self.assertIn('dia._opciones_sueno()', self.controlador)
        self.assertIn('dia.jornada.get("sueno_escenas", [])', self.controlador)
        self.assertNotIn("Sueno.noche(", self.controlador)

    def test_recurrencia_es_presentacion_pura(self):
        for termino in (
            "CollisionShape3D",
            "Area3D",
            "Interactuable3D",
            "Control.new",
            "SuenoFormas",
            "Planta.",
            "SuenoObjetivos",
            "Jornada.",
            "Partida",
            "FileAccess",
            "guardar(",
        ):
            self.assertNotIn(termino, self.recurrencia)
        self.assertIn("MeshInstance3D.new()", self.recurrencia)
        self.assertIn('firma.name = "RecurrenciaSimbolica"', self.recurrencia)

    def test_firma_depende_solo_de_motivos_ya_presentes(self):
        self.assertIn('get_meta("motivo_simbolico", "")', self.recurrencia)
        self.assertIn('"ciclo-centro"', self.recurrencia)
        self.assertIn('"laberinto"', self.recurrencia)
        self.assertIn('"doble"', self.recurrencia)
        self.assertIn('"umbral"', self.recurrencia)
        for termino in ("CartasOcultas", "ObjetosOniricos", "leido_hoy", "tarot"):
            self.assertNotIn(termino, self.recurrencia)

    def test_transformacion_es_determinista_y_acotada(self):
        self.assertIn("Azar.derivar_texto", self.recurrencia)
        self.assertIn("indice_escena", self.recurrencia)
        self.assertIn("total_escenas", self.recurrencia)
        for termino in ("randomize", "randi(", "randf(", "RandomNumberGenerator.new"):
            self.assertNotIn(termino, self.recurrencia)

    def test_corte_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 30, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
