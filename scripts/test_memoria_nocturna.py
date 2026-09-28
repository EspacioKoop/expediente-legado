import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "memoria_nocturna.gd"
CONTRADICCIONES = ROOT / "godot" / "guion" / "memoria_nocturna_contradicciones.gd"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_memoria_nocturna.gd"


class MemoriaNocturnaTest(unittest.TestCase):
    def test_modelo_es_puro_y_no_lee_fuentes_globales(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn("class_name MemoriaNocturna", fuente)
        self.assertIn("static func analizar(", fuente)
        self.assertNotIn("FileAccess", fuente)
        self.assertNotIn("casos.json", fuente)
        self.assertNotIn("Partida", fuente)
        self.assertNotIn("Jornada", fuente)

    def test_relaciones_exigen_pista_ya_descubierta(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn("not descubiertas.has(pista_id)", fuente)
        self.assertIn('pista.get("registroOrigen2", "")', fuente)
        self.assertIn("not conteos.has(folio_a)", fuente)
        self.assertIn("not conteos.has(folio_b)", fuente)

    def test_no_expone_texto_de_pistas_como_salida(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        cuerpo = fuente.split("static func _relaciones_conocidas", 1)[1]
        self.assertNotIn('pista.get("descripcion"', cuerpo)
        self.assertIn('"pistas": []', cuerpo)
        self.assertIn('"folios": pareja', cuerpo)

    def test_contradicciones_son_explicitas_y_no_inferidas_de_texto(self) -> None:
        catalogo = CONTRADICCIONES.read_text(encoding="utf-8")
        modelo = MODELO.read_text(encoding="utf-8")

        self.assertIn('"caso_id": "caso@1"', catalogo)
        self.assertIn('"registros": ["memo1@1", "actaContraloria1@1"]', catalogo)
        self.assertIn('"pistas_requeridas": ["pista1@1", "pista20@1"]', catalogo)
        self.assertNotIn('"contenido"', catalogo)
        self.assertNotIn('"descripcion"', catalogo)
        self.assertIn("contradicciones_declaradas", modelo)
        self.assertIn("_contradicciones_conocidas(", modelo)
        self.assertNotIn('pista.get("descripcion"', modelo.split("static func _contradicciones_conocidas", 1)[1])

    def test_repeticion_es_determinista_y_separada_de_relaciones(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn('"intensidad_maxima"', fuente)
        self.assertIn('"repeticiones"', fuente)
        self.assertIn("folios_ordenados.sort()", fuente)
        self.assertIn("claves.sort()", fuente)

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
