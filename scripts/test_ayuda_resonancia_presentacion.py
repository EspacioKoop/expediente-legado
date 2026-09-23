from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRESENTER = ROOT / "godot" / "guion" / "sueno_ayuda_resonancia_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_ayuda_resonancia_app.gd"
SCENE = ROOT / "godot" / "escenas" / "dia.tscn"


class AyudaResonanciaPresentacionTest(unittest.TestCase):
    def test_controller_esta_montado_en_dia(self):
        escena = SCENE.read_text(encoding="utf-8")
        self.assertIn(
            'path="res://guion/dia_ayuda_resonancia_app.gd"',
            escena,
        )
        self.assertIn('name="AyudaResonanciaController"', escena)

    def test_presentacion_es_solo_visual_y_sonora(self):
        codigo = PRESENTER.read_text(encoding="utf-8")
        self.assertIn("OmniLight3D.new()", codigo)
        self.assertIn("AudioStreamPlayer3D.new()", codigo)
        for prohibido in ("Area3D", "CollisionShape3D", "StaticBody3D", "CharacterBody3D"):
            self.assertNotIn(prohibido, codigo)

    def test_capa_online_no_conoce_estado_canonico(self):
        codigo = (
            PRESENTER.read_text(encoding="utf-8")
            + CONTROLLER.read_text(encoding="utf-8")
        )
        for prohibido in (
            "SuenoObjetivos",
            "Partida",
            "_guardar_o_avisar",
            "pistas_descubiertas",
            "veredicto",
            "economia",
            "vidas",
        ):
            self.assertNotIn(prohibido, codigo)


if __name__ == "__main__":
    unittest.main()
