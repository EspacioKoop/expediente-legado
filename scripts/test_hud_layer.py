from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "hud_layer.gd"


class HUDLayerTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_declara_superficies_separadas(self):
        self.assertIn("class_name HUDLayer", self.source)
        for nombre in ["ESTADO", "INTERACCION", "TUTORIAL", "DIALOGO", "MODAL"]:
            self.assertIn(f"const {nombre}", self.source)

    def test_dialogo_gana_a_tutorial_e_interaccion(self):
        self.assertIn("INTERACCION: 100", self.source)
        self.assertIn("TUTORIAL: 200", self.source)
        self.assertIn("DIALOGO: 300", self.source)
        self.assertIn("MODAL: 400", self.source)
        self.assertIn("return tipo == _primaria_activa()", self.source)

    def test_modal_oculta_el_resto(self):
        self.assertIn("if esta_activa(MODAL):", self.source)
        self.assertIn("return tipo == MODAL", self.source)

    def test_estado_puede_coexistir_sin_ser_instruccion_primaria(self):
        self.assertIn("if tipo == ESTADO:", self.source)
        self.assertIn("return true", self.source)
        self.assertNotIn("ESTADO: 500", self.source)

    def test_superficies_transitorias_no_dejan_referencias_liberadas(self):
        self.assertIn("_superficies[tipo] = weakref(control)", self.source)
        self.assertIn("var referencia: WeakRef", self.source)
        self.assertIn("referencia.get_ref() as Control", self.source)
        self.assertIn("caducadas.append(tipo)", self.source)
        self.assertIn("_superficies.erase(tipo)", self.source)

    def test_no_decide_contenido_ni_hardcodea_teclas(self):
        self.assertNotIn('"E"', self.source)
        self.assertNotIn("texto =", self.source)
        self.assertNotIn("Companeros.frase_de", self.source)


if __name__ == "__main__":
    unittest.main()
