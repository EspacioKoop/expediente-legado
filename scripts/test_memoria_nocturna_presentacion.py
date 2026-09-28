import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ADAPTADOR = ROOT / "godot" / "guion" / "memoria_nocturna_presentacion.gd"
DIA = ROOT / "godot" / "guion" / "dia_sueno_app.gd"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_memoria_nocturna_presentacion.gd"


class MemoriaNocturnaPresentacionTest(unittest.TestCase):
    def test_presentacion_es_visual_y_pura(self) -> None:
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn("class_name MemoriaNocturnaPresentacion", fuente)
        self.assertIn('"luces"', fuente)
        self.assertIn('"ambiente_energia"', fuente)
        self.assertIn("COLOR_CONTRADICCION_A", fuente)
        self.assertIn("COLOR_CONTRADICCION_B", fuente)
        self.assertIn('analisis.get("contradicciones", [])', fuente)
        self.assertNotIn("FileAccess", fuente)
        self.assertNotIn("casos.json", fuente)
        self.assertNotIn('"salidas"] =', fuente)
        self.assertNotIn('"planta"] =', fuente)

    def test_runtime_usa_el_contrato_semantico_sin_reimplementarlo(self) -> None:
        fuente = DIA.read_text(encoding="utf-8")
        compacto = "".join(fuente.split())
        self.assertIn("MemoriaNocturna.analizar(", compacto)
        self.assertIn("MemoriaNocturnaPresentacion.aplicar(", compacto)
        self.assertIn("contenido.casos", compacto)
        self.assertIn('partida.estado.get("pistas_descubiertas",[])', compacto)
        self.assertIn("MemoriaNocturnaContradicciones.todas()", compacto)

    def test_regresion_ejecutable_en_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                str(PRUEBA.relative_to(ROOT / "godot")),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
