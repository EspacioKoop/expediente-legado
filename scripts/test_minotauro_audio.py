import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "godot" / "guion" / "sueno_minotauro_audio.gd"
VERTICAL = ROOT / "godot" / "guion" / "sueno_minotauro_3d.gd"
SMOKE = ROOT / "godot" / "pruebas" / "pruebas_minotauro_audio.gd"


class MinotauroAudioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.audio = AUDIO.read_text(encoding="utf-8")
        cls.vertical = VERTICAL.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_audio_es_procedural_determinista_y_sin_asset_externo(self):
        self.assertIn("class_name SuenoMinotauroAudio", self.audio)
        self.assertIn("AudioStreamWAV.new()", self.audio)
        self.assertIn("AudioStreamWAV.FORMAT_16_BITS", self.audio)
        self.assertIn("AudioStreamWAV.LOOP_FORWARD", self.audio)
        self.assertIn("1103515245", self.audio)
        self.assertIn("sin(TAU * 43.0 * t)", self.audio)
        self.assertNotIn("randf()", self.audio)
        self.assertNotIn("load(", self.audio)
        self.assertNotIn("preload(", self.audio)

    def test_estados_existentes_controlan_volumen_y_pitch(self):
        for presencia in ("lejano", "respiracion", "cruce", "cerca"):
            self.assertIn(f'"{presencia}"', self.audio)
        self.assertIn("static func volumen_db(presencia: String)", self.audio)
        self.assertIn("static func pitch_scale(presencia: String)", self.audio)
        self.assertLess(self.audio.index('"lejano": -31.0'), self.audio.index('"cerca": -10.0'))

    def test_vertical_espacializa_audio_en_la_misma_presencia(self):
        self.assertIn("var _audio_presencia: AudioStreamPlayer3D", self.vertical)
        self.assertIn("_audio_presencia = AudioStreamPlayer3D.new()", self.vertical)
        self.assertIn('_audio_presencia.name = "RespiracionMinotauro"', self.vertical)
        self.assertIn("_audio_presencia.stream = SuenoMinotauroAudio.respiracion()", self.vertical)
        self.assertIn("_presencia.add_child(_audio_presencia)", self.vertical)
        self.assertIn("_audio_presencia.play()", self.vertical)
        self.assertIn("SuenoMinotauroAudio.volumen_db(presencia)", self.vertical)
        self.assertIn("SuenoMinotauroAudio.pitch_scale(presencia)", self.vertical)

    def test_no_introduce_ia_timing_o_selector_paralelo(self):
        self.assertNotIn("NavigationAgent", self.audio)
        self.assertNotIn("Timer", self.audio)
        self.assertNotIn("SemillasOniricas", self.audio)
        self.assertNotIn("MitologiasNoche", self.audio)
        self.assertNotIn("Input.", self.audio)
        self.assertNotIn("_process", self.audio)

    def test_smoke_ejerce_stream_y_dos_escalones_de_presencia(self):
        self.assertIn("SuenoMinotauroAudio.respiracion()", self.smoke)
        self.assertIn("as AudioStreamPlayer3D", self.smoke)
        self.assertIn('SuenoMinotauroAudio.volumen_db("respiracion")', self.smoke)
        self.assertIn('SuenoMinotauroAudio.volumen_db("cruce")', self.smoke)
        self.assertEqual(self.smoke.count("minotauro.marcar_y_cruzar"), 2)

    @unittest.skipUnless(
        shutil.which(os.environ.get("GODOT_BIN", "godot4")),
        "Godot no está disponible en PATH",
    )
    def test_smoke_godot_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="minotauro-audio-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    "res://pruebas/pruebas_minotauro_audio.gd",
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=120,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")


if __name__ == "__main__":
    unittest.main()
