from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PANTALLA = ROOT / "godot" / "guion" / "pantalla.gd"
SHADER_MEDIA_LUNA = ROOT / "godot" / "arte" / "media_luna.gdshader"
SHADER_EMISION_CRT = ROOT / "godot" / "arte" / "emision_crt.gdshader"


class PantallaContenidoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = PANTALLA.read_text(encoding="utf-8")
        cls.shader_media_luna = SHADER_MEDIA_LUNA.read_text(encoding="utf-8")
        cls.shader_emision_crt = SHADER_EMISION_CRT.read_text(encoding="utf-8")

    def test_sin_fichero_conserva_nieve(self):
        self.assertIn('declaracion.get("fichero", "")', self.codigo)
        self.assertIn("if not _montar_video", self.codigo)
        self.assertIn("_montar_nieve", self.codigo)
        self.assertIn('lienzo.name = "Nieve"', self.codigo)

    def test_fichero_valido_usa_video_nativo(self):
        self.assertIn("ResourceLoader.exists(fichero)", self.codigo)
        self.assertIn("recurso is VideoStream", self.codigo)
        self.assertIn("VideoStreamPlayer.new()", self.codigo)
        self.assertIn("video.autoplay = true", self.codigo)
        self.assertIn("video.loop = true", self.codigo)

    def test_la_emision_no_anade_audio(self):
        self.assertIn("video.volume_db = -80.0", self.codigo)
        self.assertNotIn("AudioStreamPlayer", self.codigo)

    def test_media_luna_sigue_disponible_como_compatibilidad(self):
        self.assertIn('contenido == "media_luna"', self.codigo)
        self.assertIn("_montar_media_luna", self.codigo)
        self.assertIn('lienzo.name = "MediaLuna"', self.codigo)
        self.assertIn("SubViewport.UPDATE_ONCE", self.codigo)
        self.assertIn("shader_type canvas_item", self.shader_media_luna)

    def test_emision_crt_es_procedural_estatica_y_tiene_seis_canales(self):
        self.assertIn('contenido == "emision_crt"', self.codigo)
        self.assertIn("_montar_emision_crt", self.codigo)
        self.assertIn('lienzo.name = "EmisionCRT"', self.codigo)
        self.assertIn('material.set_shader_parameter("canal", clampi(canal, 0, 5))', self.codigo)
        self.assertIn("SubViewport.UPDATE_ONCE", self.codigo)
        self.assertIn("uniform int canal = 0", self.shader_emision_crt)
        for funcion in ("informativo", "deporte", "institucional", "tecnica", "anomalia", "ocio"):
            self.assertIn(f"vec3 {funcion}(vec2 uv)", self.shader_emision_crt)

    def test_no_introduce_dependencia_de_ffmpeg(self):
        self.assertNotIn("ffmpeg", self.codigo.lower())
        self.assertNotIn("GDExtension", self.codigo)


if __name__ == "__main__":
    unittest.main()
