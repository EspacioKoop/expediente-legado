from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
PROPS = RAIZ / "godot" / "escenas" / "suenos" / "props_284"
ESCENA = PROPS / "muro_torre_castillo.tscn"
MALLA = PROPS / "muro_arco_castillo_psx.obj"
README = PROPS / "README.md"


class SuenoAssets284CastilloTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.malla = MALLA.read_text(encoding="utf-8")
        cls.readme = README.read_text(encoding="utf-8")

    def test_la_portada_visible_ya_no_es_arquitectura_de_cajas(self):
        self.assertIn("muro_arco_castillo_psx.obj", self.escena)
        self.assertNotIn("BoxMesh", self.escena)
        self.assertNotIn("CylinderMesh", self.escena)
        self.assertGreaterEqual(self.malla.count("\nv "), 180)
        self.assertGreaterEqual(self.malla.count("\ng Arch_"), 9)

    def test_la_silueta_declara_arco_torres_y_cubiertas_apuntadas(self):
        self.assertIn("g Keystone", self.malla)
        self.assertIn("g Tower_L", self.malla)
        self.assertIn("g Tower_R", self.malla)
        self.assertIn("g Roof_L", self.malla)
        self.assertIn("g Roof_R", self.malla)

        vertices = []
        for linea in self.malla.splitlines():
            if linea.startswith("v "):
                _, x, y, z = linea.split()
                vertices.append((float(x), float(y), float(z)))
        xs = [vertice[0] for vertice in vertices]
        ys = [vertice[1] for vertice in vertices]
        self.assertGreater(max(xs) - min(xs), 10.0)
        self.assertGreater(max(ys), 7.0)

    def test_es_malla_original_diffable_sin_deuda_de_procedencia(self):
        self.assertTrue(MALLA.suffix == ".obj")
        self.assertNotIn("mtllib ", self.malla)
        self.assertNotIn("usemtl ", self.malla)
        self.assertIn("Contenido original", self.readme)
        self.assertIn("muro_arco_castillo_psx.obj", self.readme)


if __name__ == "__main__":
    unittest.main()
