from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MUSICA = ROOT / "godot" / "guion" / "musica.gd"


class MusicaPuntualTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = MUSICA.read_text(encoding="utf-8")

    def test_solo_declara_momentos_dramaticos(self):
        self.assertIn('"careo": ""', self.codigo)
        self.assertIn('"final": ""', self.codigo)
        for prohibido in ('"archivo"', '"oficina"', '"calle"', '"casa"', '"sueño"'):
            self.assertNotIn(prohibido, self.codigo)

    def test_un_slot_sin_asset_es_silencio_y_no_error(self):
        self.assertIn("if fichero.is_empty():", self.codigo)
        self.assertIn("return null", self.codigo)
        self.assertIn("ResourceLoader.exists(ruta)", self.codigo)

    def test_hay_un_solo_reproductor_central_por_escena(self):
        self.assertIn('const NODO := "MusicaPuntual"', self.codigo)
        self.assertIn("detener(nodo)", self.codigo)
        self.assertIn("AudioStreamPlayer.new()", self.codigo)
        self.assertIn("get_node_or_null(NODO)", self.codigo)

    def test_ogg_respeta_el_bucle_del_momento(self):
        self.assertIn("pista is AudioStreamOggVorbis", self.codigo)
        self.assertIn('"careo": true', self.codigo)
        self.assertIn('"final": false', self.codigo)
        self.assertIn("pista.loop = en_bucle(nombre)", self.codigo)

    def test_no_duplica_efectos_ni_ambiente(self):
        self.assertNotIn("Sonido.sonar", self.codigo)
        self.assertNotIn("AudioStreamWAV.new()", self.codigo)
        self.assertNotIn("fluorescente", self.codigo.lower())


if __name__ == "__main__":
    unittest.main()
