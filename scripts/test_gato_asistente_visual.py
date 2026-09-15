from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
AVATAR = ROOT / "godot" / "guion" / "gato_asistente_2d.gd"
AYUDA = ROOT / "godot" / "guion" / "gato_ayuda.gd"
ATLAS = ROOT / "godot" / "arte" / "gato_asistente_gba.svg"


class GatoAsistenteVisualTest(unittest.TestCase):
    def setUp(self):
        self.dia = DIA_GATO.read_text(encoding="utf-8")
        self.avatar = AVATAR.read_text(encoding="utf-8")
        self.ayuda = AYUDA.read_text(encoding="utf-8")
        self.atlas = ATLAS.read_text(encoding="utf-8")

    def test_el_asistente_se_ancla_abajo_a_la_derecha(self):
        self.assertIn("Control.PRESET_BOTTOM_RIGHT", self.dia)
        self.assertIn('conjunto.name = "AsistenteSiga"', self.dia)
        self.assertNotIn("Control.PRESET_BOTTOM_LEFT", self.dia)

    def test_bocadillo_avatar_y_puntero_son_piezas_separadas(self):
        self.assertIn('burbuja.name = "BocadilloGato"', self.dia)
        self.assertIn('puntero.name = "PunteroBocadilloGato"', self.dia)
        self.assertIn('avatar.name = "GatoAsistente"', self.dia)
        self.assertIn("Polygon2D.new()", self.dia)

    def test_el_estado_sigue_viniendo_de_gato_ayuda(self):
        self.assertIn("GatoAyuda.lineas_asistente(gato, contexto)", self.dia)
        self.assertIn("GatoAyuda.contexto_siga", self.dia)
        self.assertIn("GatoAyuda.nivel(gato)", self.dia)
        self.assertNotIn("afinidad", self.dia.lower())
        self.assertIn("dias_sin_comer", self.ayuda)
        self.assertIn("func configurar(nivel: String,", self.avatar)
        self.assertIn("NIVEL_COMPLETO := GatoAyuda.COMPLETA", self.avatar)
        self.assertIn("NIVEL_ESCASO := GatoAyuda.ESCASA", self.avatar)

    def test_reduccion_movimiento_congela_la_animacion(self):
        self.assertIn('preferencias.get("reduccion_movimiento", false)', self.dia)
        self.assertIn("set_process(not reduccion_movimiento)", self.avatar)
        self.assertIn("if _reduccion_movimiento:", self.avatar)
        self.assertIn("return FRAME_IDLE", self.avatar)
        self.assertIn("return 0.0", self.avatar)

    def test_el_avatar_usa_atlas_gba_original(self):
        self.assertIn("gato_asistente_gba.svg", self.avatar)
        self.assertIn("Texture2D", self.avatar)
        self.assertIn("draw_texture_rect_region", self.avatar)
        self.assertIn("TEXTURE_FILTER_NEAREST", self.avatar)
        self.assertIn("ANCHO_FRAME := 48.0", self.avatar)
        self.assertIn("ALTO_FRAME := 64.0", self.avatar)
        self.assertIn("Asset original", self.atlas)
        self.assertNotIn("draw_colored_polygon", self.avatar)

    def test_las_poses_respiran_sin_redisenar_el_atlas(self):
        self.assertIn("func _respiracion() -> float:", self.avatar)
        self.assertIn("func _amplitud_respiracion(frame: int) -> Vector2:", self.avatar)
        self.assertIn("sin((_tiempo / 4.0) * TAU)", self.avatar)
        self.assertIn("TAMANO_DIBUJO.y * escala_y", self.avatar)
        self.assertIn("ALTO - tamano.y", self.avatar)
        self.assertIn("frame == FRAME_HAMBRIENTO", self.avatar)
        self.assertIn("frame == FRAME_ALERTA or frame == FRAME_MIRANDO", self.avatar)
        # La profundidad nueva sale del render; no se rediseña ni amplía el atlas.
        self.assertEqual(self.atlas.count('id="frame-'), 8)

    def test_no_invade_la_barra_de_botones_del_visor(self):
        # #285 (segunda vuelta): el offset fijo original tapaba Relacionar/Marcar
        # folio/Imputar. En vez de adivinar otro número fijo, se pregunta al
        # árbol real por el Button más alto y se sube el conjunto si hace falta,
        # así que cualquier traducción o resolución sigue quedando cubierta.
        self.assertIn("func _colocar_asistente_siga(", self.dia)
        self.assertIn("func _limite_superior_botones_visor(", self.dia)
        self.assertIn("nodo is Button", self.dia)
        # Un botón oculto (como el anexo sin desbloquear) no debe contar como
        # límite: el fix original de este mismo bug lo subía ~600px y dejaba
        # al gato prácticamente fuera de pantalla.
        self.assertIn("nodo.is_visible_in_tree()", self.dia)
        self.assertIn("nodo.size.y > 0.0", self.dia)
        self.assertIn("call_deferred(\"_colocar_asistente_siga\"", self.dia)
        self.assertIn("MARGEN_BOTONES_ASISTENTE", self.dia)

    def test_el_conjunto_se_puede_arrastrar_y_la_posicion_persiste(self):
        self.assertIn("func _al_input_asistente_siga(", self.dia)
        self.assertIn("func _fijar_posicion_libre_asistente(", self.dia)
        self.assertIn("func _guardar_posicion_asistente_siga(", self.dia)
        self.assertIn('CLAVE_POSICION_ASISTENTE := "posicion_asistente_gato"', self.dia)
        self.assertIn("conjunto.mouse_filter = Control.MOUSE_FILTER_PASS", self.dia)

    def test_el_atlas_reserva_ocho_posturas_discretas(self):
        frames = (
            "idle",
            "alerta",
            "parpadeo",
            "hambriento",
            "satisfecho",
            "loaf",
            "mirando",
            "espalda",
        )
        self.assertEqual(self.atlas.count('id="frame-'), len(frames))
        for frame in frames:
            self.assertIn(f'id="frame-{frame}"', self.atlas)
        self.assertIn("FRAME_PARPADEO", self.avatar)
        self.assertIn("FRAME_ALERTA", self.avatar)
        self.assertIn("FRAME_MIRANDO", self.avatar)
        self.assertIn("FRAME_HAMBRIENTO", self.avatar)


if __name__ == "__main__":
    unittest.main()
