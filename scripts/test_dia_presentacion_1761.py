from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
PRESENTACION = ROOT / "godot" / "guion" / "dia_presentacion_app.gd"


class DiaPresentacion1761Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")

    def test_dia_conserva_hooks_historicos(self):
        self.assertIn("func _andar(delta: float) -> void:", self.dia)
        self.assertIn("func _suelo_pisado() -> String:", self.dia)
        self.assertIn("func _sonar(nombre: String) -> void:", self.dia)
        self.assertIn("_presentacion_app.andar(", self.dia)
        self.assertIn("_presentacion_app.sonar(nombre)", self.dia)

    def test_audio_y_distancia_viven_en_presentacion(self):
        for token in (
            "const METROS_POR_ZANCADA := 0.72",
            "AudioStreamPlayer.new()",
            "AudioStreamPlayer3D.new()",
            "Sonido.paso_sobre(suelo)",
            "randf_range(0.94, 1.06)",
        ):
            self.assertIn(token, self.presentacion)
            self.assertNotIn(token, self.dia)

    def test_suelo_sigue_dependiendo_del_espacio_y_clima_reales(self):
        self.assertIn('String(jornada.get("fase", "")) == "trayecto"', self.presentacion)
        self.assertIn("Clima.NIEVE", self.presentacion)
        self.assertIn('espacio_actual.get("textura_suelo", "")', self.presentacion)

    def test_dia_baja_del_umbral_750(self):
        self.assertLess(len(self.dia.splitlines()), 750)


if __name__ == "__main__":
    unittest.main()
