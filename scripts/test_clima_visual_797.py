from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot" / "guion" / "dia_clima_visual_app.gd"
CAPTURADOR = ROOT / "godot" / "pruebas" / "capturar_climas_797.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
PROYECTO = ROOT / "godot" / "project.godot"


class ClimaVisual797Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.capturador = CAPTURADOR.read_text(encoding="utf-8")
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

    def test_niebla_usa_environment_real_y_perfiles_distintos(self) -> None:
        self.assertIn('"fog_density": 0.028', self.controlador)
        self.assertIn('"fog_density": 0.100', self.controlador)
        self.assertIn('"fog_density": 0.040', self.controlador)
        self.assertIn('"background_energy": 0.54', self.controlador)
        self.assertIn('"background_energy": 1.14', self.controlador)
        self.assertIn("ambiente.fog_enabled = bool(perfil", self.controlador)

    def test_la_volumetrica_sigue_al_renderer_y_no_al_proyecto(self) -> None:
        # El contrato no es qué renderer usa el proyecto hoy —desde #275 es
        # Forward+—, sino que la niebla volumétrica se decida por la capacidad
        # real del renderer en ejecución. Así el guion sirve igual si un día se
        # vuelve a Compatibility o si se exporta a un objetivo que no lo admita.
        self.assertIn('get_current_rendering_method()) != "forward_plus"', self.controlador)
        self.assertIn("ambiente.volumetric_fog_enabled = false", self.controlador)
        self.assertIn('renderer/rendering_method="forward_plus"', self.proyecto)

    def test_precipitacion_sigue_al_jugador_y_tiene_viento(self) -> None:
        self.assertIn("nodo.global_position = caminante.global_position", self.controlador)
        self.assertIn("particulas.amount = 900 if nieve else 1450", self.controlador)
        self.assertIn("particulas.randomness = 0.62 if nieve else 0.38", self.controlador)
        self.assertIn("proceso.direction = (", self.controlador)
        self.assertIn("Vector3(1.80 * viento, -3.0, 0.35 * viento)", self.controlador)
        self.assertIn(
            "Vector2(0.070, 0.070) if nieve else Vector2(0.034, 0.54)",
            self.controlador,
        )

    def test_reduccion_movimiento_baja_densidad_y_deriva(self) -> None:
        self.assertIn(
            'PreferenciasSiga.cargar().get("reduccion_movimiento", false)',
            self.controlador,
        )
        self.assertIn("particulas.amount = 360 if nieve else 620", self.controlador)
        self.assertIn("var viento := 0.35 if _reduccion_movimiento else 1.0", self.controlador)
        self.assertIn("material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED", self.controlador)
        self.assertIn("material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED", self.controlador)
        self.assertIn("transicion and not _reduccion_movimiento", self.controlador)

    def test_cielo_cambia_por_estado_y_se_restaura(self) -> None:
        self.assertIn("PARAMETROS_CIELO_CLIMA", self.controlador)
        for parametro in (
            "cielo_alto",
            "horizonte",
            "ocaso",
            "ocaso_mezcla",
            "resplandor_fuerza",
            "bruma_fuerza",
            "nubes",
            "nube_color",
            "cirros",
            "cirro_color",
            "luz_lunar_nubes",
            "via_lactea",
            "estrellas",
            "estrellas_secundarias",
            "luna_halo",
        ):
            self.assertIn(f'"{parametro}"', self.controlador)
        self.assertIn("CIELO_BASE_ALTO", self.controlador)
        self.assertIn("_perfil_ambiente(Clima.DESPEJADO)", self.controlador)
        self.assertIn(
            "material.set_shader_parameter(parametro, perfil[parametro])",
            self.controlador,
        )

    def test_capas_nuevas_del_cielo_reaccionan_a_los_cinco_climas(self) -> None:
        perfiles = {
            "despejado": (
                '"nubes": 0.28',
                '"via_lactea": 0.08',
                '"estrellas": 0.50',
                '"luna_halo": 0.09',
            ),
            "nublado": (
                '"nubes": 0.76',
                '"nube_color": Color(0.18, 0.19, 0.22)',
                '"cirros": 0.56',
                '"cirro_color": Color(0.22, 0.23, 0.26)',
                '"via_lactea": 0.012',
                '"estrellas": 0.08',
            ),
            "lluvia": (
                '"nubes": 0.92',
                '"nube_color": Color(0.075, 0.095, 0.135)',
                '"cirros": 0.68',
                '"cirro_color": Color(0.10, 0.12, 0.16)',
                '"via_lactea": 0.0',
                '"luna_halo": 0.025',
            ),
            "niebla": (
                '"bruma_fuerza": 0.86',
                '"nube_color": Color(0.30, 0.31, 0.33)',
                '"cirro_color": Color(0.34, 0.35, 0.37)',
                '"estrellas": 0.0',
                '"estrellas_secundarias": 0.0',
                '"luna_halo": 0.012',
            ),
            "nieve": (
                '"resplandor_fuerza": 0.78',
                '"nube_color": Color(0.28, 0.34, 0.43)',
                '"cirro_color": Color(0.38, 0.44, 0.54)',
                '"luz_lunar_nubes": 0.44',
                '"estrellas": 0.12',
                '"luna_halo": 0.12',
            ),
        }
        for estado, fragmentos in perfiles.items():
            with self.subTest(estado=estado):
                for fragmento in fragmentos:
                    self.assertIn(fragmento, self.controlador)

    def test_coches_psx_reaccionan_al_clima_canonico(self) -> None:
        self.assertIn("_aplicar_coches_clima(dia, estado)", self.controlador)
        self.assertIn('get_node_or_null("CochesPsxCC0")', self.controlador)
        self.assertIn("CochesPsxCC0.aplicar_clima(lote, estado)", self.controlador)

    def test_suelo_climatico_usa_pelicula_y_acumulaciones_sin_colision(self) -> None:
        self.assertIn('NODO_SUELO_CLIMA := "ClimaSueloVisual"', self.controlador)
        self.assertIn('superficie.name = "Pelicula"', self.controlador)
        self.assertIn('parche.name = "Acumulacion%02d" % indice', self.controlador)
        self.assertIn("var disco := CylinderMesh.new()", self.controlador)
        self.assertIn("disco.radial_segments = 12", self.controlador)
        self.assertIn("var cantidad := 24 if nieve else 12", self.controlador)
        self.assertNotIn("StaticBody3D.new()", self.controlador)
        self.assertNotIn("CollisionShape3D.new()", self.controlador)

    def test_cambio_runtime_interpola_atmosfera_y_cielo(self) -> None:
        self.assertIn("TRANSICION_DURACION := 0.65", self.controlador)
        self.assertIn("_tween_clima = create_tween()", self.controlador)
        self.assertIn('_tween_clima.tween_property(', self.controlador)
        self.assertIn("_transicionar_parametro_cielo", self.controlador)
        self.assertIn("_cancelar_transicion()", self.controlador)

    def test_clima_tiene_cama_sonora_procedural_sin_assets_externos(self) -> None:
        self.assertIn('NODO_AUDIO_CLIMA := "ClimaAmbiente"', self.controlador)
        self.assertIn("AudioStreamPlayer.new()", self.controlador)
        self.assertIn("AudioStreamWAV.new()", self.controlador)
        self.assertIn("AudioStreamWAV.LOOP_FORWARD", self.controlador)
        self.assertIn("func _muestra_audio", self.controlador)
        self.assertIn("var rafaga :=", self.controlador)

    def test_capturador_sigue_comparando_los_cinco_estados(self) -> None:
        for estado in ["DESPEJADO", "NUBLADO", "LLUVIA", "NIEBLA", "NIEVE"]:
            self.assertIn(f"Clima.{estado}", self.capturador)
        self.assertIn('dia._entrar_en("trayecto")', self.capturador)
        self.assertIn("dia._caminante.situar(entrada, mirada)", self.capturador)
        self.assertIn('get_node("Camara") as Camera3D', self.capturador)
        self.assertIn("camara.rotation.x = deg_to_rad(35.0)", self.capturador)
        self.assertIn('"%s_cielo.png" % estado', self.capturador)
        self.assertIn("func _guardar_captura", self.capturador)


if __name__ == "__main__":
    unittest.main()
