from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
SCRIPT = RAIZ / "godot/guion/correccion_visual_npc_275.gd"
PROYECTO = RAIZ / "godot/project.godot"


class CorreccionVisualNpc275Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.script = SCRIPT.read_text(encoding="utf-8")
        cls.proyecto = PROYECTO.read_text(encoding="utf-8")

    def test_correccion_se_carga_despues_del_vestuario(self):
        vestuario = 'VestuarioHumano3D="*res://guion/vestuario_humano_3d.gd"'
        correccion = 'CorreccionVisualNPC275="*res://guion/correccion_visual_npc_275.gd"'
        self.assertIn(vestuario, self.proyecto)
        self.assertIn(correccion, self.proyecto)
        self.assertLess(self.proyecto.index(vestuario), self.proyecto.index(correccion))

    def test_cabeza_sale_del_torso_y_no_de_headtop_end(self):
        self.assertIn('RATIO_CABEZA_TORSO := 0.30', self.script)
        self.assertIn('get_bone_global_pose(cabeza).origin.y', self.script)
        self.assertIn('get_bone_global_pose(cadera).origin.y', self.script)
        self.assertIn('alto_torso * RATIO_CABEZA_TORSO', self.script)
        self.assertNotIn('HeadTop_End', self.script.split('extends Node', 1)[1])

    def test_ajusta_cara_existente_y_da_cabeza_al_fallback(self):
        self.assertIn('_ajustar_cara(cara, alto_cabeza_objetivo)', self.script)
        self.assertIn('_cabeza_generica(', self.script)
        self.assertIn('"PielCabeza275"', self.script)
        self.assertIn('"Cabello275"', self.script)
        self.assertIn('Modelos.PERFILES_FACIALES', self.script)

    def test_cara_existente_puede_alcanzar_el_objetivo_sin_suelo_artificial(self):
        self.assertIn('minf(alto_objetivo / alto_actual, 1.0)', self.script)
        self.assertNotIn('clampf(alto_objetivo / alto_actual, 0.25, 1.0)', self.script)

    def test_malla_base_pasa_a_underlay_sin_tapar_el_vestuario_runtime(self):
        self.assertIn('_pintar_importado(pieza, color_base.darkened(0.12))', self.script)
        self.assertIn('EMISION_LEGIBILIDAD := 0.07', self.script)
        self.assertIn('set_shader_parameter("emision_fuerza", EMISION_LEGIBILIDAD)', self.script)
        self.assertIn('nodo.owner != null', self.script)
        self.assertIn('material_override = material', self.script)

    def test_no_toca_fisica_ni_movimiento(self):
        for prohibido in (
            'CollisionShape3D',
            'CollisionPolygon3D',
            'CharacterBody3D',
            'move_and_slide',
            'velocity =',
        ):
            self.assertNotIn(prohibido, self.script)


if __name__ == "__main__":
    unittest.main()
