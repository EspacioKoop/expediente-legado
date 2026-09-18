from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SELECCION = ROOT / "godot" / "guion" / "seleccion_nocturna.gd"
JORNADA = ROOT / "godot" / "guion" / "jornada.gd"
SUENO = ROOT / "godot" / "guion" / "sueno.gd"
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
SUITE = ROOT / "godot" / "pruebas" / "pruebas.gd"


class SeleccionNocturnaContratoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.seleccion = SELECCION.read_text(encoding="utf-8")
        cls.jornada = JORNADA.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.suite = SUITE.read_text(encoding="utf-8")

    def test_tres_huecos_solo_con_documentos_leidos(self):
        self.assertIn("const MAX_DOCUMENTOS := 3", self.seleccion)
        self.assertIn('not leido_hoy.has(folio)', self.seleccion)
        self.assertIn('jornada["seleccion_nocturna"] = seleccion.duplicate()', self.seleccion)

    def test_jornada_persiste_y_limpia_la_seleccion(self):
        self.assertIn('"seleccion_nocturna": []', self.jornada)
        self.assertIn("static func preparar_sueno(", self.jornada)
        self.assertIn('jornada["seleccion_nocturna"] = []', self.jornada)

    def test_semilla_conserva_orden_y_repeticion(self):
        self.assertIn("seleccion_nocturna: Array = []", self.sueno)
        self.assertIn('texto += "|memoria:" + str(folio)', self.sueno)
        self.assertIn('opciones.get("seleccion_nocturna", [])', self.sueno)

    def test_reparto_y_recalculo_usan_la_misma_memoria(self):
        self.assertIn("SeleccionNocturna.opciones_sueno(jornada, _opciones_sueno())", self.dia)
        self.assertIn('opciones.get("seleccion_nocturna", [])', self.dia)
        self.assertIn("opciones = SeleccionNocturna.opciones_sueno(jornada, opciones)", self.dia)

    def test_hay_regresion_godot_ejecutable(self):
        self.assertIn('load("res://pruebas/pruebas_seleccion_nocturna.gd").todo(comprobar_cb)', self.suite)


if __name__ == "__main__":
    unittest.main()
