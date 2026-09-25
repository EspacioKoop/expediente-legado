from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROPS = ROOT / "godot" / "guion" / "mitologias_435_props.gd"
PREVIEW = ROOT / "godot" / "arte" / "mitologias_435" / "preview_props_3d.gd"


class Mitologias435PropsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.props = PROPS.read_text(encoding="utf-8")
        cls.preview = PREVIEW.read_text(encoding="utf-8")

    def test_siete_props_reutilizables(self):
        fabricas = (
            "tablilla_uruk",
            "archivador_onirico",
            "panoplia_aquiles",
            "busto_hidra",
            "compuerta_ryu",
            "balanza_duat",
            "legajo_siga",
        )
        for fabrica in fabricas:
            self.assertIn(f"static func {fabrica}()", self.props)
            self.assertIn(f"Mitologias435Props.{fabrica}()", self.preview)

    def test_reutiliza_pbr_mergeados(self):
        for material in (
            "arcilla_uruk",
            "metal_archivo_oxidado",
            "bronce_votivo",
            "escama_hidra",
            "jade_ryu_humedo",
            "caliza_duat",
            "papel_archivo_envejecido",
        ):
            self.assertIn(f"materiales/{material}.tres", self.props)

    def test_es_solo_escenografia(self):
        prohibidos = (
            "SemillasOniricas",
            "Input.",
            "activar_semilla",
            "resolver(",
            "CanvasLayer",
        )
        for token in prohibidos:
            self.assertNotIn(token, self.props)


if __name__ == "__main__":
    unittest.main()
