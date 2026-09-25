from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MUSICA = ROOT / "godot" / "guion" / "musica.gd"
CAREO = ROOT / "godot" / "guion" / "careo_app.gd"
FINAL_POLITICO = ROOT / "godot" / "guion" / "dia_climax_hastur_app.gd"
GITATTRIBUTES = ROOT / ".gitattributes"


class MusicaPuntualTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = MUSICA.read_text(encoding="utf-8")
        cls.careo = CAREO.read_text(encoding="utf-8")
        cls.final_politico = FINAL_POLITICO.read_text(encoding="utf-8")
        cls.atributos = GITATTRIBUTES.read_text(encoding="utf-8")

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

    def test_ogg_musical_nuevo_entra_por_lfs_sin_migrar_efectos(self):
        regla = "godot/assets/audio/musica/*.ogg filter=lfs diff=lfs merge=lfs -text"
        self.assertIn(regla, self.atributos)
        self.assertNotIn("\n*.ogg   filter=lfs", self.atributos)

    def test_catalogo_musical_solo_resuelve_su_subdirectorio(self):
        self.assertIn('const RUTA := "res://assets/audio/musica/"', self.codigo)

    def test_careo_gobierna_inicio_y_fin_de_la_musica(self):
        inicio = re.findall(
            r'Musica\s*\.\s*reproducir\(\s*self\s*,\s*"careo"\s*\)',
            self.careo,
        )
        paradas = re.findall(r"Musica\s*\.\s*detener\(\s*self\s*\)", self.careo)
        self.assertEqual(1, len(inicio))
        self.assertGreaterEqual(len(paradas), 2)
        self.assertIn("func _exit_tree() -> void:", self.careo)

    def test_final_politico_gobierna_inicio_y_fin_de_la_musica(self):
        inicio = re.findall(
            r'Musica\s*\.\s*reproducir\(\s*self\s*,\s*"final"\s*\)',
            self.final_politico,
        )
        paradas = re.findall(
            r"Musica\s*\.\s*detener\(\s*self\s*\)",
            self.final_politico,
        )
        self.assertEqual(1, len(inicio))
        self.assertGreaterEqual(len(paradas), 2)
        self.assertIn("func _cerrar_final() -> void:", self.final_politico)
        self.assertIn("func _exit_tree() -> void:", self.final_politico)

    def test_no_duplica_efectos_ni_ambiente(self):
        self.assertNotIn("Sonido.sonar", self.codigo)
        self.assertNotIn("AudioStreamWAV.new()", self.codigo)
        self.assertNotIn("fluorescente", self.codigo.lower())


if __name__ == "__main__":
    unittest.main()
