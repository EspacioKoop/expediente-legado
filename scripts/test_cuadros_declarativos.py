from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CUADROS = RAIZ / "godot" / "guion" / "cuadros.gd"


class CuadrosDeclarativosTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = CUADROS.read_text(encoding="utf-8")

    def test_no_conoce_salas_ni_assets_concretos(self):
        self.assertNotIn("OFICINA", self.codigo)
        self.assertNotIn("piramide", self.codigo.lower())
        self.assertNotIn(".jpg", self.codigo)
        self.assertNotIn(".png", self.codigo)

    def test_ruta_se_declara_por_dato(self):
        self.assertIn('declaracion.get("textura", "")', self.codigo)
        self.assertIn('"res://assets/texturas/%s" % nombre', self.codigo)

    def test_fallback_no_rompe_si_falta_recurso(self):
        self.assertIn("ResourceLoader.exists(ruta)", self.codigo)
        self.assertIn('cuadro["usar_textura"] = tiene_textura(cuadro)', self.codigo)
        self.assertIn("COLOR_FALLBACK", self.codigo)

    def test_limita_tamano_degenerado(self):
        self.assertIn("TAM_MINIMO", self.codigo)
        self.assertIn("maxf(tam.x, TAM_MINIMO.x)", self.codigo)
        self.assertIn("maxf(tam.y, TAM_MINIMO.y)", self.codigo)


if __name__ == "__main__":
    unittest.main()
