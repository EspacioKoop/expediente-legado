from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "godot" / "arte" / "ryu_440" / "kit_visual_ryu.gd"
SCENE = ROOT / "godot" / "arte" / "ryu_440" / "muestra_kit_visual_ryu.tscn"
DOC = ROOT / "godot" / "arte" / "ryu_440" / "README.md"


class KitVisualRyu440Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.script = SCRIPT.read_text(encoding="utf-8")
        cls.scene = SCENE.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_declara_las_piezas_visual_especificas(self) -> None:
        for nombre in (
            "ToriiSuspendido",
            "CascadaInvertida",
            "NubeInterior",
            "PuenteVertebra",
            "FarolesDeLluvia",
        ):
            self.assertIn(f'"{nombre}"', self.script)
            self.assertIn(nombre, self.doc)

    def test_es_procedural_y_sin_assets_externos(self) -> None:
        for primitiva in ("BoxMesh.new()", "CylinderMesh.new()", "SphereMesh.new()"):
            self.assertIn(primitiva, self.script)
        for carga in ("load(", "preload(", ".png", ".jpg", ".webp", ".glb", ".gltf"):
            self.assertNotIn(carga, self.script.lower())

    def test_no_modifica_el_runtime_de_ryu(self) -> None:
        for termino in (
            "SuenoRyu",
            "SemillasOniricas",
            "MitologiasNoche",
            "Interactuable3D",
            "dia.tscn",
        ):
            self.assertNotIn(termino, self.script)

    def test_la_muestra_es_abrible_y_tiene_iluminacion_y_camara(self) -> None:
        self.assertIn('path="res://arte/ryu_440/kit_visual_ryu.gd"', self.scene)
        self.assertIn('type="DirectionalLight3D"', self.scene)
        self.assertIn('type="OmniLight3D"', self.scene)
        self.assertIn('type="Camera3D"', self.scene)
        self.assertIn("current = true", self.scene)

    def test_documenta_que_no_sustituye_el_gate_humano(self) -> None:
        self.assertIn("#398/#181", self.doc)
        self.assertIn("no está conectado al runtime", self.doc)
        self.assertIn("reduccion_movimiento", self.doc)


if __name__ == "__main__":
    unittest.main()
