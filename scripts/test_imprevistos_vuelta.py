from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
IMPREVISTOS = ROOT / "godot" / "guion" / "imprevistos.gd"
JORNADA = ROOT / "godot" / "guion" / "jornada.gd"
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
SUENO = ROOT / "godot" / "guion" / "dia_sueno_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
SUITE = ROOT / "godot" / "pruebas" / "pruebas.gd"


class ImprevistosVueltaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.imprevistos = IMPREVISTOS.read_text(encoding="utf-8")
        cls.jornada = JORNADA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")
        cls.suite = SUITE.read_text(encoding="utf-8")

    def test_plan_es_acotado_y_reproducible(self):
        self.assertIn("const MIN_POR_VUELTA := 2", self.imprevistos)
        self.assertIn("const MAX_POR_VUELTA := 4", self.imprevistos)
        self.assertIn("const MAX_FUERTES := 1", self.imprevistos)
        self.assertIn("const UNO_DE_CADA_SIN_IMPREVISTOS := 5", self.imprevistos)
        self.assertIn('Azar.derivar(raiz, "vida", [vuelta, INDICE_PLAN])', self.imprevistos)
        self.assertIn("tirada_vuelta % UNO_DE_CADA_SIN_IMPREVISTOS == 0", self.imprevistos)
        self.assertIn('Azar.generador(raiz, "vida", [vuelta, INDICE_PLAN])', self.imprevistos)
        self.assertIn("const DIAS_CANDIDATOS := [2, 4, 6, 8, 10, 12]", self.imprevistos)
        for token in ("randomize()", "randi()", "randf()", ".shuffle()"):
            self.assertNotIn(token, self.imprevistos)

    def test_no_hay_deuda_y_la_consecuencia_queda_para_casa(self):
        self.assertIn("static func resolver_imprevisto_del_dia", self.jornada)
        resolver = self.jornada.split("static func resolver_imprevisto_del_dia", 1)[1]
        self.assertIn("Imprevistos.pendiente(jornada)", resolver)
        self.assertIn("gastar(jornada, coste)", resolver)
        self.assertIn("Imprevistos.resolver(jornada, pagado)", resolver)
        self.assertIn('"consecuencias"', self.imprevistos)
        self.assertNotIn('jornada["dinero"] -=', self.imprevistos)

    def test_dormir_resuelve_el_evento_una_sola_vez_y_lo_devuelve(self):
        dormir = self.jornada.split("static func dormir", 1)[1]
        self.assertIn("resolver_imprevisto_del_dia(jornada)", dormir)
        self.assertIn('"imprevisto": imprevisto', dormir)

    def test_el_jugador_recibe_feedback_del_gasto(self):
        self.assertIn("_aviso_imprevisto(noche)", self.dia)
        self.assertIn("_aviso_imprevisto(noche)", self.sueno)
        self.assertIn("DIA_IMPREVISTO_PAGADO", self.textos)
        self.assertIn("DIA_IMPREVISTO_IMPAGADO", self.textos)

    def test_hay_prueba_godot_real_en_suite(self):
        self.assertIn("PruebasImprevistos.todo(comprobar_cb)", self.suite)


if __name__ == "__main__":
    unittest.main()
