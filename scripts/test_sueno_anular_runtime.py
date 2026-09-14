from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
FAMILIAS = ROOT / "godot" / "guion" / "sueno_familias.gd"
FORMAS = ROOT / "godot" / "guion" / "sueno_formas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno.gd"


class SuenoAnularRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.familias = FAMILIAS.read_text(encoding="utf-8")
        cls.formas = FORMAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")

    def test_anular_es_un_contorno_concavo_unico(self):
        bloque = self.familias.split("\tANULAR:", 1)[1].split("\tFRAGMENTADA:", 1)[0]
        self.assertIn('"contorno":', bloque)
        self.assertNotIn('"hueco":', bloque)
        self.assertGreaterEqual(bloque.count("Vector2("), 16)
        self.assertIn('"entrada": Vector3(-17, 0, 0)', bloque)

    def test_patio_usa_la_familia_anular(self):
        bloque = self.formas.split('"patio":', 1)[1].split('"peine":', 1)[0]
        self.assertIn('"familia_poligonal": SuenoFamilias.ANULAR', bloque)

    def test_runtime_poligonal_sigue_siendo_generico(self):
        self.assertIn('forma.get("familia_poligonal", "")', self.sueno)
        self.assertIn('resultado["contorno"] = familia["contorno"]', self.sueno)
        self.assertNotIn('if id == "patio"', self.sueno)
        self.assertNotIn('if id == "embudo"', self.sueno)


if __name__ == "__main__":
    unittest.main()
