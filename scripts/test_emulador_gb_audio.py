from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "godot" / "native" / "siga98_gb" / "src"
AUDIO_UI = ROOT / "godot" / "guion" / "emulador_portatil_audio_app.gd"
SMOKE = ROOT / "godot" / "pruebas" / "emulador_gb_smoke.gd"
DOC = ROOT / "docs" / "emulador-gb-audio.md"


class EmuladorGBAudioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.header = (NATIVE / "siga98_gb.h").read_text(encoding="utf-8")
        cls.cpp = (NATIVE / "siga98_gb.cpp").read_text(encoding="utf-8")
        cls.audio_ui = AUDIO_UI.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_sameboy_expone_pcm_s16le_estereo_a_48khz(self):
        self.assertIn("AUDIO_SAMPLE_RATE = 48000", self.cpp)
        self.assertIn("AUDIO_BYTES_PER_FRAME = 4", self.cpp)
        self.assertIn("GB_apu_set_sample_callback", self.cpp)
        self.assertIn("GB_set_sample_rate", self.cpp)
        self.assertIn("capture_audio_sample", self.cpp)
        self.assertIn("append_s16le", self.cpp)
        self.assertIn("drain_audio_pcm16", self.header)
        self.assertIn("audio_sample_rate", self.header)

    def test_buffer_pcm_esta_acotado_y_se_vacia_al_drenar(self):
        self.assertIn("MAX_AUDIO_BUFFER_BYTES", self.cpp)
        self.assertIn("impl->audio_pcm.size() + AUDIO_BYTES_PER_FRAME", self.cpp)
        self.assertIn("impl->audio_pcm.clear()", self.cpp)
        self.assertIn("GB_set_user_data", self.cpp)
        self.assertIn("GB_get_user_data", self.cpp)

    def test_capacidad_publica_se_activa_con_consumer_godot(self):
        self.assertIn("bool Siga98GB::supports_audio() const", self.cpp)
        bloque = self.cpp.split("bool Siga98GB::supports_audio() const", 1)[1]
        self.assertIn("return true;", bloque.split("}", 1)[0])
        self.assertIn("AudioStreamGenerator.new()", self.audio_ui)
        self.assertIn('call("drain_audio_pcm16")', self.audio_ui)
        self.assertIn("supports_audio() == true", self.doc)

    def test_consumer_godot_separa_audio_y_acota_backlog(self):
        self.assertIn('name = "AudioEmuladoPortatil"', self.audio_ui)
        self.assertIn("AudioStreamGeneratorPlayback", self.audio_ui)
        self.assertIn("pcm.decode_s16(offset)", self.audio_ui)
        self.assertIn("pcm.decode_s16(offset + 2)", self.audio_ui)
        self.assertIn("MAX_FRAMES_AUDIO_PENDIENTE", self.audio_ui)
        self.assertIn("get_frames_available()", self.audio_ui)
        self.assertIn("push_buffer(lote)", self.audio_ui)
        self.assertIn("clear_buffer()", self.audio_ui)
        self.assertIn("set_audio_emulado_muted", self.audio_ui)
        self.assertIn("set_audio_emulado_volumen", self.audio_ui)

    def test_smoke_ejecuta_y_drena_pcm_real(self):
        self.assertIn("func _probar_audio_nativo", self.smoke)
        self.assertIn('emulador.call("audio_sample_rate")', self.smoke)
        self.assertIn('emulador.call("drain_audio_pcm16")', self.smoke)
        self.assertIn("pcm.size() % BYTES_POR_MUESTRA_ESTEREO", self.smoke)
        self.assertIn("not vacio.is_empty()", self.smoke)
        self.assertIn('if not bool(emulador.call("supports_audio")):', self.smoke)


if __name__ == "__main__":
    unittest.main()
