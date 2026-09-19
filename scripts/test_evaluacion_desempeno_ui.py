import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "godot/guion/evaluacion_desempeno_siga.gd").read_text(encoding="utf-8")
ADAPTADOR = (ROOT / "godot/guion/dia_escritorio_siga_app.gd").read_text(encoding="utf-8")
TEXTOS = (ROOT / "godot/datos/textos.csv").read_text(encoding="utf-8")
PRUEBA_GODOT = "res://pruebas/pruebas_evaluacion_desempeno_ui.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class EvaluacionDesempenoUiTests(unittest.TestCase):
    def test_es_una_app_de_consulta_del_escritorio(self):
        self.assertIn("class_name EvaluacionDesempenoSiga", UI)
        self.assertIn("EvaluacionDesempeno.historial(_estado)", UI)
        self.assertIn('name = "Vidas"', UI)
        self.assertIn('name = "DetalleEvaluacion"', UI)
        self.assertIn('var _evaluaciones_app: EscritorioSigaApp', ADAPTADOR)
        self.assertIn('"evaluaciones-desempeno"', ADAPTADOR)
        self.assertIn('Callable(self, "_crear_evaluaciones")', ADAPTADOR)
        self.assertIn("EvaluacionDesempenoSiga.new()", ADAPTADOR)

    def test_consulta_no_escribe_partida_ni_otorga_recompensas(self):
        for prohibido in (
            'partida[',
            '_estado[',
            "partida.guardar(",
            "Jornada.gastar(",
            "Jornada.gastar_accion(",
            "pistas_descubiertas",
            "sellos_obtenidos",
        ):
            self.assertNotIn(prohibido, UI)

    def test_muestra_todas_las_categorias_sin_nota_total(self):
        for categoria in (
            "productividad",
            "precipitacion",
            "cuidado_gato",
            "liquidez",
            "exploracion_onirica",
        ):
            self.assertIn(f'"{categoria}"', UI)
        self.assertNotIn("puntuacion_total", UI)
        self.assertNotIn("nota_total", UI)

    def test_textos_viven_en_catalogo(self):
        for clave in (
            "EVALUACION_APP_TITULO,",
            "EVALUACION_CABECERA,",
            "EVALUACION_AYUDA,",
            "EVALUACION_FILA,",
            "EVALUACION_VIDA,",
            "EVALUACION_MOTIVO,",
            "EVALUACION_CATEGORIA_PRODUCTIVIDAD,",
            "EVALUACION_CATEGORIA_PRECIPITACION,",
            "EVALUACION_CATEGORIA_GATO,",
            "EVALUACION_CATEGORIA_LIQUIDEZ,",
            "EVALUACION_CATEGORIA_SUENO,",
            "EVALUACION_RANGO_BAJA,",
            "EVALUACION_RANGO_MEDIA,",
            "EVALUACION_RANGO_ALTA,",
            "EVALUACION_VACIO,",
        ):
            self.assertIn(clave, TEXTOS)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 12, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
