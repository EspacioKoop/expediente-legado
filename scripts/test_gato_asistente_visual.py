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

    def test_el_avatar_usa_atlas_gba_original(self):
        self.assertIn("gato_asistente_gba.svg", self.avatar)
        self.assertIn("Texture2D", self.avatar)
        self.assertIn("draw_texture_rect_region", self.avatar)
        self.assertIn("TEXTURE_FILTER_NEAREST", self.avatar)
        self.assertIn("ANCHO_FRAME := 48.0", self.avatar)
        self.assertIn("ALTO_FRAME := 64.0", self.avatar)
        self.assertIn("Asset original", self.atlas)
        self.assertNotIn("draw_colored_polygon", self.avatar)

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
