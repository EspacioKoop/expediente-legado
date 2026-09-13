from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
AMBIENTE = RAIZ / "godot" / "guion" / "ambiente.gd"


class AmbienteArchivoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = AMBIENTE.read_text(encoding="utf-8")

    def test_separa_ambiente_de_efectos_y_musica(self):
        self.assertIn("class_name Ambiente", self.texto)
        self.assertNotIn("Sonido.sonar", self.texto)
        self.assertNotIn("Musica.", self.texto)

    def test_primer_corte_solo_activa_archivo(self):
        self.assertIn('if fase != "archivo"', self.texto)
        self.assertIn("return zumbido_archivo()", self.texto)

    def test_zumbido_es_procedural_y_determinista(self):
        self.assertIn("AudioStreamWAV.new()", self.texto)
        self.assertIn("sin(TAU * 50.0 * t)", self.texto)
        self.assertIn("1103515245", self.texto)
        self.assertNotIn("randf()", self.texto)
        self.assertNotIn("randi()", self.texto)

    def test_el_stream_es_continuo_y_en_bucle(self):
        self.assertIn("AudioStreamWAV.LOOP_FORWARD", self.texto)
        self.assertIn("loop_begin = 0", self.texto)
        self.assertIn("loop_end = muestras", self.texto)

    def test_un_solo_reproductor_central(self):
        self.assertIn('const NODO := "AmbienteContinuo"', self.texto)
        self.assertIn("detener(nodo)", self.texto)
        self.assertIn("AudioStreamPlayer.new()", self.texto)
        self.assertIn("get_node_or_null(NODO)", self.texto)

    def test_no_finge_assets_ni_procedencia(self):
        self.assertNotIn("res://assets/audio/", self.texto)
        self.assertNotIn("ResourceLoader", self.texto)
        self.assertNotIn("procedencia.json", self.texto)


if __name__ == "__main__":
    unittest.main()
