from pathlib import Path
import re
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

    def test_hay_cama_para_las_cuatro_fases_del_recorrido(self):
        for fase in ("archivo", "trayecto", "casa", "sueño"):
            with self.subTest(fase=fase):
                self.assertRegex(
                    self.texto,
                    rf'"{re.escape(fase)}"',
                )
        self.assertIn('const FASES := ["archivo", "trayecto", "casa", "sueño"]', self.texto)
        self.assertIn("if not FASES.has(fase)", self.texto)
        self.assertIn("return null", self.texto)

    def test_perfiles_sonoros_son_distintos(self):
        self.assertIn("sin(TAU * 50.0 * t) * 0.055", self.texto)
        self.assertIn("sin(TAU * 31.5 * t) * 0.018", self.texto)
        self.assertIn("var compresor :=", self.texto)
        self.assertIn("sin(TAU * 41.5 * t) * 0.007", self.texto)

    def test_generacion_es_procedural_y_determinista(self):
        self.assertIn("AudioStreamWAV.new()", self.texto)
        self.assertIn("1103515245", self.texto)
        self.assertIn("_ruido(indice, 11)", self.texto)
        self.assertIn("_ruido(indice, 37)", self.texto)
        self.assertIn("_ruido(indice, 73)", self.texto)
        self.assertIn("_ruido(indice, 101)", self.texto)
        self.assertNotIn("randf()", self.texto)
        self.assertNotIn("randi()", self.texto)

    def test_streams_son_continuos_en_bucle_y_se_cachean(self):
        self.assertIn("AudioStreamWAV.LOOP_FORWARD", self.texto)
        self.assertIn("loop_begin = 0", self.texto)
        self.assertIn("loop_end = muestras", self.texto)
        self.assertIn("static var _pistas: Dictionary = {}", self.texto)
        self.assertIn("_pistas[fase] = _crear_pista(fase)", self.texto)

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
