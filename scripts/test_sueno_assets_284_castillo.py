from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
PROPS = RAIZ / "godot" / "escenas" / "suenos" / "props_284"
ESCENA = PROPS / "muro_torre_castillo.tscn"
MALLA = PROPS / "muro_arco_castillo_psx.obj"
ESCALERA_ESCENA = PROPS / "escalera_anular_castillo.tscn"
ESCALERA_MALLA = PROPS / "escalera_anular_castillo_psx.obj"
PATIO = PROPS / "patio_castillo_onirico.tscn"
README = PROPS / "README.md"


class SuenoAssets284CastilloTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.malla = MALLA.read_text(encoding="utf-8")
        cls.escalera_escena = ESCALERA_ESCENA.read_text(encoding="utf-8")
        cls.escalera_malla = ESCALERA_MALLA.read_text(encoding="utf-8")
        cls.patio = PATIO.read_text(encoding="utf-8")
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

    def test_la_escalera_anular_abandona_los_peldanos_de_boxmesh(self):
        self.assertIn("escalera_anular_castillo_psx.obj", self.escalera_escena)
        self.assertNotIn("BoxMesh", self.escalera_escena)
        self.assertGreaterEqual(self.escalera_malla.count("\ng Step_"), 14)
        self.assertIn("g Column", self.escalera_malla)
        self.assertGreaterEqual(self.escalera_malla.count("\nv "), 120)

    def test_el_patio_compone_una_escena_reconocible_y_reutilizable(self):
        self.assertEqual(self.patio.count('instance=ExtResource("1_muro")'), 3)
        self.assertIn("EscaleraImposible", self.patio)
        self.assertEqual(self.patio.count('instance=ExtResource("3_estandarte")'), 2)
        self.assertIn("PlaneMesh", self.patio)
        self.assertNotIn("BoxMesh", self.patio)

    def test_son_mallas_originales_diffables_sin_deuda_de_procedencia(self):
        for ruta, contenido in ((MALLA, self.malla), (ESCALERA_MALLA, self.escalera_malla)):
            self.assertEqual(ruta.suffix, ".obj")
            self.assertNotIn("mtllib ", contenido)
            self.assertNotIn("usemtl ", contenido)
        self.assertIn("Contenido original", self.readme)
        self.assertIn("muro_arco_castillo_psx.obj", self.readme)
        self.assertIn("escalera_anular_castillo_psx.obj", self.readme)
        self.assertIn("patio_castillo_onirico.tscn", self.readme)


if __name__ == "__main__":
    unittest.main()
