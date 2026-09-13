from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "assets" / "psx-style-cars.md"
GITATTRIBUTES = ROOT / ".gitattributes"


class TestPsxStyleCarsContract(unittest.TestCase):
    def test_fuente_y_licencia_quedan_fijadas(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("https://ggbot.itch.io/psx-style-cars", texto)
        self.assertIn("CC0 1.0 Universal", texto)
        self.assertIn("GGBotNet", texto)

    def test_seleccion_minima_no_importa_el_pack_completo(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("Car 01", texto)
        self.assertIn("Car 03", texto)
        self.assertIn("Car 04", texto)
        self.assertIn("No importar el pack completo", texto)

    def test_escala_se_normaliza_por_modelo(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("unidad de escala entre coches no es correcta", texto)
        self.assertIn("normalizarse individualmente", texto)

    def test_binarios_relevantes_estan_cubiertos_por_lfs(self):
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.glb   filter=lfs", atributos)
        self.assertIn("*.blend filter=lfs", atributos)
        self.assertIn("*.png   filter=lfs", atributos)

    def test_pr_binario_exige_procedencia_y_sha(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("godot/assets/procedencia.json", texto)
        self.assertIn("sha256", texto)
        self.assertIn("Git LFS real", texto)


if __name__ == "__main__":
    unittest.main()
