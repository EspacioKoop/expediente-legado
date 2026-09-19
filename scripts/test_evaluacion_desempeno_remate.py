import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
PRESENTACION = ROOT / "godot" / "guion" / "evaluacion_desempeno_cinematica.gd"
DESPIDO = ROOT / "godot" / "guion" / "despido_cinematica.gd"
VISOR = ROOT / "godot" / "guion" / "visor_sello_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
PRUEBA_GODOT = "res://pruebas/pruebas_evaluacion_desempeno_remate.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class EvaluacionDesempenoRemateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.despido = DESPIDO.read_text(encoding="utf-8")
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")

    def test_usa_exclusivamente_el_historial_sellado(self):
        self.assertIn("EvaluacionDesempeno.historial(estado)", self.presentacion)
        self.assertNotIn('estado.get("jornada"', self.presentacion)
        self.assertNotIn("RemateVida.resumir", self.presentacion)
        self.assertNotIn("EvaluacionDesempeno.calcular", self.presentacion)

    def test_no_hay_nota_total_ni_recompensa(self):
        for prohibido in (
            "puntuacion",
            "nota_total",
            "score",
            "Partida.guardar",
            "acciones +=",
            "dinero +=",
            "pistas_descubiertas",
            "sellos_obtenidos",
        ):
            self.assertNotIn(prohibido, self.presentacion)

    def test_hay_contrastes_sin_jerarquia_global(self):
        for clave in (
            "EVALUACION_REMATE_PRODUCTIVA_PRECIPITADA",
            "EVALUACION_REMATE_CUIDADOS_LIQUIDEZ",
            "EVALUACION_REMATE_SUENO_PRODUCTIVIDAD",
            "EVALUACION_REMATE_NEUTRA",
        ):
            self.assertIn(clave, self.presentacion)
            self.assertIn(clave + ",", self.textos)
        self.assertIn("EVALUACION_REMATE_ROTULO,", self.textos)

    def test_el_despido_real_anexa_el_informe(self):
        self.assertIn("EvaluacionDesempenoCinematica.planos_de(estado, vistas)", self.despido)
        self.assertIn("DespidoCinematica.planos_con_remate(", self.visor)
        self.assertNotIn(
            "DespidoCinematica.planos_de(\n\t\t\tgato_presente",
            self.visor,
        )

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 9, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
