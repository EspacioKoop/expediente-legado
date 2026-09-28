import csv
import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "dialogo_horario_companeros.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_dialogo_horario_963.gd"


class DialogoHorario963Test(unittest.TestCase):
    def test_modelo_es_puro_y_no_controla_jornada(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn("class_name DialogoHorarioCompaneros", fuente)
        self.assertIn("static func resolver(", fuente)
        for prohibido in ("Partida", "Jornada", "FileAccess", "guardar", "acciones"):
            self.assertNotIn(prohibido, fuente)

    def test_runtime_lo_usa_como_ultimo_fallback(self) -> None:
        fuente = DIA.read_text(encoding="utf-8")
        llamada = "DialogoHorarioCompaneros.resolver("
        self.assertIn(llamada, fuente)
        self.assertIn("actor_id, Jornada.hora_decimal(jornada)", fuente)
        self.assertGreater(fuente.index(llamada), fuente.index("var clave_social"))
        self.assertGreater(fuente.index(llamada), fuente.index("var clave_religiosa"))

    def test_todas_las_claves_tienen_texto(self) -> None:
        with TEXTOS.open(encoding="utf-8", newline="") as fh:
            filas = {fila[0]: fila[1] for fila in csv.reader(fh) if len(fila) >= 2}

        esperadas = {
            f"COMPA_HORA_{actor}_{franja}"
            for actor in ("CUNADO", "TELEFONO", "BECARIO", "JUBILACION", "RIEGOS")
            for franja in ("MEDIODIA", "TARDE", "NOCHE")
        }
        self.assertEqual(esperadas, {clave for clave in filas if clave.startswith("COMPA_HORA_")})
        for clave in esperadas:
            self.assertTrue(filas[clave].strip(), clave)

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
