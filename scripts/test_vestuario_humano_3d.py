from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VESTUARIO = ROOT / "godot" / "guion" / "vestuario_humano_3d.gd"
PROYECTO = ROOT / "godot" / "project.godot"


class VestuarioHumano3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vestuario = VESTUARIO.read_text(encoding="utf-8")
        cls.proyecto = PROYECTO.read_text(encoding="utf-8")

    def test_el_pase_esta_activo_como_autoload(self):
        self.assertIn(
            'VestuarioHumano3D="*res://guion/vestuario_humano_3d.gd"',
            self.proyecto,
        )

    def test_solo_viste_el_asset_humano_del_pack(self):
        self.assertIn(
            'const RUTA_PERSONA := "res://assets/modelos/persona.fbx"',
            self.vestuario,
        )
        self.assertIn("String(nodo.scene_file_path) == RUTA_PERSONA", self.vestuario)

    def test_la_ropa_sigue_el_esqueleto_sin_reescalarlo(self):
        self.assertIn("BoneAttachment3D.new()", self.vestuario)
        self.assertIn('["LeftArm", "UpperArm_L", "upperarm_l"]', self.vestuario)
        self.assertIn('["RightArm", "UpperArm_R", "upperarm_r"]', self.vestuario)
        self.assertNotIn("esqueleto.scale =", self.vestuario)
        self.assertNotIn("CollisionShape3D", self.vestuario)

    def test_las_siluetas_son_deterministas(self):
        self.assertIn('"nombre": "estrecho"', self.vestuario)
        self.assertIn('"nombre": "medio"', self.vestuario)
        self.assertIn('"nombre": "robusto"', self.vestuario)
        self.assertIn("absi(hash(clave))", self.vestuario)
        self.assertNotIn("randf(", self.vestuario)
        self.assertNotIn("randi(", self.vestuario)

    def test_el_volumen_prioriza_hombros_y_torso_alargado(self):
        self.assertIn('"VestuarioHombros"', self.vestuario)
        self.assertIn('alto_torso * 0.27 * float(perfil["ancho"])', self.vestuario)
        self.assertIn('alto_torso * 0.135 * float(perfil["fondo"])', self.vestuario)
        self.assertIn('alto_torso * 0.47 * float(perfil["largo"])', self.vestuario)
        self.assertIn("Vector3(ancho * 0.78, largo * 0.18, fondo * 0.90)", self.vestuario)
        self.assertIn("malla.radius = ancho_torso * 0.085", self.vestuario)

    def test_conserva_el_shader_visual_del_proyecto(self):
        self.assertIn("load(Espacio3D.SHADER_PSX)", self.vestuario)
        self.assertIn('get_shader_parameter("color_base")', self.vestuario)
        self.assertIn('set_shader_parameter("color_base", color)', self.vestuario)


if __name__ == "__main__":
    unittest.main()
