from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot" / "guion" / "dia_clima_visual_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
PROYECTO = ROOT / "godot" / "project.godot"


class ClimaVisual797Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.proyecto = PROYECTO.read_text(encoding="utf-8")

    def test_controller_se_conecta_como_hijo_sin_cambiar_raiz(self) -> None:
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)
        self.assertIn('path="res://guion/dia_clima_visual_app.gd" id="34"', self.escena)
        self.assertIn('[node name="ClimaVisualController" type="Node" parent="."]', self.escena)
        self.assertIn('script = ExtResource("34")', self.escena)

    def test_merge_con_main_conserva_los_controllers_nuevos(self) -> None:
        self.assertIn('path="res://guion/dia_buscar_ejecutar_app.gd" id="30"', self.escena)
        self.assertIn('path="res://guion/dia_contaminacion_gato_app.gd" id="31"', self.escena)
        self.assertIn('path="res://guion/dia_climax_os98_app.gd" id="32"', self.escena)
        self.assertIn(
            'path="res://guion/dia_publicaciones_encontrables_app.gd" id="33"',
            self.escena,
        )

    def test_niebla_usa_environment_real(self) -> None:
        self.assertIn("ambiente.fog_enabled = true", self.controlador)
        self.assertIn("ambiente.fog_density = densidad", self.controlador)
        self.assertIn("ambiente.fog_height_density = densidad_altura", self.controlador)
        self.assertIn("ambiente.fog_sky_affect = afecta_cielo", self.controlador)

    def test_renderer_compatibility_no_activa_volumetrica(self) -> None:
        self.assertIn('renderer/rendering_method="gl_compatibility"', self.proyecto)
        self.assertIn('get_current_rendering_method()) != "forward_plus"', self.controlador)
        self.assertIn("ambiente.volumetric_fog_enabled = false", self.controlador)

    def test_precipitacion_sigue_al_jugador_y_gana_lectura(self) -> None:
        self.assertIn("nodo.global_position = caminante.global_position", self.controlador)
        self.assertIn("particulas.amount = 760 if nieve else 1100", self.controlador)
        self.assertIn(
            "Vector2(0.060, 0.060) if nieve else Vector2(0.032, 0.46)",
            self.controlador,
        )

    def test_cielo_cambia_por_estado_y_se_restaura(self) -> None:
        self.assertIn('set_shader_parameter("cielo_alto", alto)', self.controlador)
        self.assertIn('set_shader_parameter("horizonte", horizonte)', self.controlador)
        self.assertIn("CIELO_BASE_ALTO", self.controlador)
        self.assertIn("background_energy_multiplier = 0.62", self.controlador)
        self.assertIn("background_energy_multiplier = 1.08", self.controlador)

    def test_lluvia_y_nieve_tienen_capa_de_suelo_sin_colision(self) -> None:
        self.assertIn('NODO_SUELO_CLIMA := "ClimaSueloVisual"', self.controlador)
        self.assertIn("caja.size = Vector3(9.0, 0.012, 34.0)", self.controlador)
        self.assertIn("material.roughness = 0.14", self.controlador)
        self.assertIn("material.roughness = 0.88", self.controlador)
        self.assertNotIn("StaticBody3D.new()", self.controlador)
        self.assertNotIn("CollisionShape3D.new()", self.controlador)

    def test_clima_tiene_cama_sonora_procedural_sin_assets_externos(self) -> None:
        self.assertIn('NODO_AUDIO_CLIMA := "ClimaAmbiente"', self.controlador)
        self.assertIn("AudioStreamPlayer.new()", self.controlador)
        self.assertIn("AudioStreamWAV.new()", self.controlador)
        self.assertIn("AudioStreamWAV.LOOP_FORWARD", self.controlador)
        self.assertIn("func _muestra_audio", self.controlador)
        self.assertIn("Clima.LLUVIA:", self.controlador)
        self.assertIn("Clima.NIEVE:", self.controlador)


if __name__ == "__main__":
    unittest.main()
