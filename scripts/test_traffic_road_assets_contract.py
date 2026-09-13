from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "assets" / "traffic-road-assets.md"
GITATTRIBUTES = ROOT / ".gitattributes"


class TestTrafficRoadAssetsContract(unittest.TestCase):
    def test_fuente_y_licencia_quedan_fijadas(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("https://milkandbanana.itch.io/traffic-road-assets", texto)
        self.assertIn("CC0 1.0 Universal", texto)
        self.assertIn("jamesdev", texto)

    def test_catalogo_no_inventa_contenido_que_la_fuente_no_publica(self):
        texto = DOC.read_text(encoding="utf-8")
        for familia in (
            "traffic cones",
            "crush barriers",
            "manhole covers",
            "roadblocks",
            "streetlights",
            "water hydrants",
        ):
            self.assertIn(familia, texto)
        self.assertIn("no anuncia", texto)
        self.assertIn("señales de tráfico", texto)
        self.assertIn("vehículos", texto)

    def test_seleccion_minima_esta_acotada_y_es_no_interactiva(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("No importar el pack completo", texto)
        self.assertIn("Manhole cover", texto)
        self.assertIn("Concrete roadblock", texto)
        self.assertIn("Traffic cone", texto)
        self.assertIn("Streetlight", texto)
        self.assertIn("sin `RigidBody3D`, IA ni interacción", texto)

    def test_trafico_movil_se_delega_a_coches_del_issue_230(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("#230", texto)
        self.assertIn("ruta simple", texto)
        self.assertIn("sin navegación, avoidance ni física de vehículo", texto)

    def test_formatos_binarios_estan_cubiertos_por_lfs(self):
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.glb   filter=lfs", atributos)
        self.assertIn("*.fbx   filter=lfs", atributos)
        self.assertIn("*.png   filter=lfs", atributos)

    def test_pr_binario_exige_procedencia_y_sha(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("godot/assets/procedencia.json", texto)
        self.assertIn("sha256", texto)
        self.assertIn("Git LFS real", texto)


if __name__ == "__main__":
    unittest.main()
