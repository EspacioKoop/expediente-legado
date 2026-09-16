from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
AUDIO = RAIZ / "godot" / "guion" / "sueno_castillo_audio.gd"
PRESENTACION = RAIZ / "godot" / "guion" / "sueno_castillo_3d.gd"
DIA_SUENO = RAIZ / "godot" / "guion" / "dia_sueno_app.gd"


class SuenoCastilloPresentacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.audio = AUDIO.read_text(encoding="utf-8")
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")

    def test_campanas_son_procedurales_deterministas_y_sin_binarios(self):
        self.assertIn("AudioStreamWAV.new()", self.audio)
        self.assertIn("LOOP_FORWARD", self.audio)
        self.assertIn("const CAMPANADAS := [0.35, 2.25, 4.65]", self.audio)
        for aleatorio in ("randf(", "randi(", "randomize("):
            self.assertNotIn(aleatorio, self.audio)
        self.assertNotIn("res://assets/audio/", self.audio)

    def test_presentacion_reutiliza_patio_mergeado_y_audio_3d(self):
        self.assertIn("patio_castillo_onirico.tscn", self.presentacion)
        self.assertIn("AudioStreamPlayer3D.new()", self.presentacion)
        self.assertIn("SuenoCastilloAudio.campanadas()", self.presentacion)
        self.assertIn('campanas.name = "CampanasSinFuente"', self.presentacion)

    def test_presentacion_solo_se_activa_por_identidad_de_datos(self):
        self.assertIn('espacio.get("identidad_onirica", "")', self.presentacion)
        self.assertIn("SuenoCastillo.ID", self.presentacion)
        self.assertNotIn('id == "patio"', self.presentacion)

    def test_presentacion_no_duplica_fisica_ni_estado_de_juego(self):
        for termino in (
            "StaticBody3D",
            "CollisionShape3D",
            "BoxMesh",
            "Rect2i",
            "Jornada.",
            "Partida",
            "dinero",
            "veredicto",
        ):
            self.assertNotIn(termino, self.presentacion)

    def test_capa_de_sueno_monta_presentacion_despues_del_mundo_base(self):
        self.assertIn("func _entrar_en(fase: String) -> void:", self.dia)
        bloque = self.dia.split("func _entrar_en(fase: String) -> void:", 1)[1]
        self.assertLess(bloque.index("super._entrar_en(fase)"), bloque.index("SuenoCastillo3D.montar"))
        self.assertIn("SuenoCastillo3D.montar(_mundo, _espacio_actual)", bloque)
        self.assertNotIn('_espacio_actual["identidad_onirica"] =', bloque)


if __name__ == "__main__":
    unittest.main()
