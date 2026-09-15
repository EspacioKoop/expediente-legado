from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
UTILERIA = ROOT / "godot" / "guion" / "casa_utileria.gd"


class VentanaCasaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.utileria = UTILERIA.read_text(encoding="utf-8")

    def test_la_ventana_tiene_vista_exterior_en_capas(self):
        for nombre in (
            'vista.name = "VistaExteriorCasa"',
            'cielo.name = "CieloExteriorCasa"',
            'edificios.name = "PerfilUrbanoCasa"',
            'luces.name = "LucesExteriorCasa"',
            'reflejos.name = "ReflejosCristalCasa"',
        ):
            self.assertIn(nombre, self.utileria)

    def test_no_vuelve_al_panel_opaco_que_origino_el_bug(self):
        self.assertNotIn('var cristal := Color(0.10, 0.14, 0.18)', self.utileria)
        self.assertNotIn(
            '_agregar_caja(ventana, Vector3.ZERO, Vector3(1.80, 1.10, 0.035), cristal)',
            self.utileria,
        )

    def test_el_exterior_sale_por_delante_de_la_cara_interior_del_muro(self):
        self.assertIn(
            'ventana.position = pos + Vector3(0, 0, 0.08)',
            self.utileria,
        )
        self.assertIn('cara interior (z=-3.4)', self.utileria)

    def test_el_exterior_tiene_profundidad_y_detalle_no_textual(self):
        self.assertIn('Vector3(0, 0, -0.045)', self.utileria)
        self.assertIn('Vector3(-0.62, -0.18, -0.027)', self.utileria)
        self.assertIn('Vector3(0.70, -0.12, -0.007)', self.utileria)
        self.assertNotIn("Label.new()", self.utileria)
        self.assertNotIn("TextMesh.new()", self.utileria)

    def test_no_introduce_asset_binario_ni_pipeline_visual_paralelo(self):
        self.assertNotIn(".png", self.utileria)
        self.assertNotIn(".jpg", self.utileria)
        self.assertNotIn("StandardMaterial3D.new()", self.utileria)
        self.assertIn("Modelos._pintar(malla, color, textura)", self.utileria)


if __name__ == "__main__":
    unittest.main()
