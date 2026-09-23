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

    def test_el_fallback_sigue_siendo_determinista(self):
        self.assertIn('"nombre": "estrecho"', self.vestuario)
        self.assertIn('"nombre": "medio"', self.vestuario)
        self.assertIn('"nombre": "robusto"', self.vestuario)
        self.assertIn("absi(hash(clave))", self.vestuario)
        self.assertNotIn("randf(", self.vestuario)
        self.assertNotIn("randi(", self.vestuario)

    def test_el_roster_tiene_perfiles_explicitos_por_identidad(self):
        self.assertIn("Companeros.CUNADO", self.vestuario)
        self.assertIn("Companeros.ROSTER", self.vestuario)
        self.assertIn("color.is_equal_approx(esperado)", self.vestuario)
        for identidad in (
            "emperador",
            "aduanero_ny",
            "correspondencia",
            "riegos",
            "fielato",
            "cunado",
            "becario",
            "jubilacion",
            "mesa_de_en_medio",
            "telefono",
        ):
            self.assertIn(f'"{identidad}":', self.vestuario)

    def test_las_siluetas_varian_hombros_cintura_y_mangas(self):
        self.assertIn('alto_torso * 0.27 * float(perfil["ancho"])', self.vestuario)
        self.assertIn('alto_torso * 0.135 * float(perfil["fondo"])', self.vestuario)
        self.assertIn('alto_torso * 0.47 * float(perfil["largo"])', self.vestuario)
        self.assertIn('ancho * float(perfil["hombros"])', self.vestuario)
        self.assertIn('ancho * float(perfil["cintura"])', self.vestuario)
        self.assertIn('float(perfil["manga"])', self.vestuario)
        self.assertIn('float(perfil["largo_manga"])', self.vestuario)

    def test_hay_vocabulario_reutilizable_de_prendas(self):
        for prenda in (
            "cuello_cerrado",
            "abrigo",
            "traje_chaleco",
            "traje",
            "chaqueta_trabajo",
            "camisa",
            "chaleco",
            "jersey",
        ):
            self.assertIn(f'"{prenda}"', self.vestuario)
        self.assertIn("func _detalle_prenda(", self.vestuario)
        self.assertIn("func _solapas(", self.vestuario)

    def test_conserva_el_shader_visual_del_proyecto(self):
        self.assertIn("load(Espacio3D.shader_del_sitio())", self.vestuario)
        self.assertIn('get_shader_parameter("color_base")', self.vestuario)
        self.assertIn('set_shader_parameter("color_base", color)', self.vestuario)
        self.assertIn('EMISION_LEGIBILIDAD := 0.06', self.vestuario)
        self.assertIn('color_base.lightened(0.16)', self.vestuario)
        self.assertIn('color_base.lightened(0.48)', self.vestuario)
        self.assertIn('color_base.darkened(0.08)', self.vestuario)
        self.assertIn('set_shader_parameter("emision_fuerza", EMISION_LEGIBILIDAD)', self.vestuario)


if __name__ == "__main__":
    unittest.main()
