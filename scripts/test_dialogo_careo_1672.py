from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "dialogo_careo_contextual.gd"
CAREO = ROOT / "godot" / "guion" / "careo_contexto_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class DialogoCareo1672Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.modelo = MODELO.read_text(encoding="utf-8")
        cls.careo = CAREO.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")

    def test_careo_ramifica_sin_tocar_reglas(self):
        self.assertIn("DialogoCareoContextual.opciones(", self.careo)
        self.assertIn("DialogoCareoContextual.registrar(", self.careo)
        self.assertIn('_botones.visible = false', self.careo)
        self.assertIn('_botones.visible = true', self.careo)
        combinado = self.modelo + self.careo
        for prohibido in (
            'estado["veredictos"] =',
            'estado["pistas_descubiertas"] =',
            "vida_jugador =",
            "vida_rival =",
            '"afinidad"',
            '"reputacion"',
        ):
            self.assertNotIn(prohibido, combinado)

    def test_copy_esta_localizado(self):
        for clave in (
            "DIALOGO_CAREO_APERTURA",
            "DIALOGO_CAREO_OPCION_PRAGMATICA",
            "DIALOGO_CAREO_OPCION_VERSION",
            "DIALOGO_CAREO_OPCION_CONTRASTE",
            "DIALOGO_CAREO_PRAGMATICA_REENTRADA",
            "DIALOGO_CAREO_VERSION_REENTRADA",
            "DIALOGO_CAREO_CONTRASTE_REENTRADA",
        ):
            self.assertIn(clave, self.textos)
            self.assertIn(clave, self.modelo + self.careo)

    def test_contrato_funciona_en_godot(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_dialogo_careo_1672.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)


if __name__ == "__main__":
    unittest.main()
