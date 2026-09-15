from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
EXTERIOR = ROOT / "godot" / "guion" / "ventana_exterior_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_ventana_clima_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class VentanaExterior3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.exterior = EXTERIOR.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_es_render_3d_real_y_no_lamina_prerenderizada(self):
        self.assertIn("SubViewport.new()", self.exterior)
        self.assertIn("Camera3D.new()", self.exterior)
        self.assertIn("MeshInstance3D.new()", self.exterior)
        self.assertIn("BoxMesh.new()", self.exterior)
        self.assertIn("CylinderMesh.new()", self.exterior)
        self.assertIn("SphereMesh.new()", self.exterior)
        self.assertIn("TAM_VIEWPORT := Vector2i(320, 180)", self.exterior)
        self.assertIn("TEXTURE_FILTER_NEAREST", self.exterior)

    def test_no_introduce_assets_externos_en_la_utileria(self):
        texto = self.exterior.lower()
        for prohibido in (".png", ".jpg", ".jpeg", ".webp", ".glb", ".obj", "load(", "preload("):
            self.assertNotIn(prohibido, texto)

    def test_cubre_los_cinco_estados_del_clima(self):
        for estado in ("Clima.DESPEJADO", "Clima.NUBLADO", "Clima.LLUVIA", "Clima.NIEBLA", "Clima.NIEVE"):
            self.assertIn(estado, self.exterior)
        self.assertIn("GPUParticles3D.new()", self.exterior)
        self.assertIn('name = "Lluvia3D"', self.exterior)
        self.assertIn('name = "Nieve3D"', self.exterior)
        self.assertIn('name = "BancosNiebla3D"', self.exterior)
        self.assertIn('name = "Nubes3D"', self.exterior)

    def test_la_casa_no_se_convierte_en_exterior(self):
        self.assertIn('dia.fase != "casa"', self.controlador)
        self.assertIn('Clima.estado(int(dia.jornada.get("dia", 1)))', self.controlador)
        self.assertIn('get_node_or_null("VentanaCasa")', self.controlador)
        self.assertNotIn('"exterior"', self.controlador)

    def test_el_controlador_esta_montado_en_dia(self):
        self.assertIn('res://guion/dia_ventana_clima_app.gd', self.dia)
        self.assertIn('[node name="VentanaClimaController"', self.dia)


if __name__ == "__main__":
    unittest.main()
