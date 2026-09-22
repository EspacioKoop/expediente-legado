import json
from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CATALOGO = RAIZ / "godot/datos/radio_domestica_98.json"
MINICADENA = RAIZ / "godot/guion/minicadena_domestica_98.gd"
CASA = RAIZ / "godot/guion/casa_utileria.gd"
VERIFICADOR = RAIZ / "scripts/verificar_godot.py"


class RadioDomestica98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        cls.minicadena = MINICADENA.read_text(encoding="utf-8")
        cls.casa = CASA.read_text(encoding="utf-8")
        cls.verificador = VERIFICADOR.read_text(encoding="utf-8")

    def test_hay_tres_emisoras_con_programacion_local(self):
        emisoras = self.catalogo["emisoras"]
        self.assertGreaterEqual(len(emisoras), 3)
        ids = {emisora["id"] for emisora in emisoras}
        self.assertEqual(len(ids), len(emisoras))
        for emisora in emisoras:
            self.assertGreaterEqual(len(emisora["programas"]), 2)
            for programa in emisora["programas"]:
                self.assertTrue(programa["desde"])
                self.assertTrue(programa["hasta"])
                self.assertTrue(programa["transcripcion"])

    def test_catalogo_no_contiene_red_ni_streaming(self):
        bruto = CATALOGO.read_text(encoding="utf-8").lower()
        self.assertNotIn("http://", bruto)
        self.assertNotIn("https://", bruto)
        self.assertNotIn("stream", bruto)

    def test_cassette_es_fuente_alternativa_con_segmentos(self):
        cassette = self.catalogo["cassette"]
        self.assertGreaterEqual(len(cassette["segmentos"]), 3)
        self.assertTrue(all(segmento["transcripcion"] for segmento in cassette["segmentos"]))

    def test_semillas_declaran_fuentes_estables_del_contrato_comun(self):
        semillas = []
        for emisora in self.catalogo["emisoras"]:
            semillas.extend(
                programa["semilla"]
                for programa in emisora["programas"]
                if "semilla" in programa
            )
        semillas.extend(
            segmento["semilla"]
            for segmento in self.catalogo["cassette"]["segmentos"]
            if "semilla" in segmento
        )
        self.assertGreaterEqual(len(semillas), 2)
        self.assertTrue(all(semilla["id_mito"] in {"simurgh", "duat", "tir_na_nog"} for semilla in semillas))
        self.assertIn("tir_na_nog", {semilla["id_mito"] for semilla in semillas})
        self.assertTrue(all(":" in semilla["fuente"] for semilla in semillas))

    def test_gdscript_no_consulta_reloj_real_y_exige_atencion(self):
        self.assertIn("Jornada.ACCIONES_POR_DIA", self.minicadena)
        self.assertIn("func escuchar_actual", self.minicadena)
        self.assertIn("atencion_requerida", self.minicadena)
        self.assertIn("SemillasOniricas", self.minicadena)
        self.assertIn("activar_semilla_onirica", self.minicadena)
        self.assertNotIn("Time.get_", self.minicadena)
        self.assertNotIn("HTTPRequest", self.minicadena)

    def test_audio_reutiliza_mixer_comun_y_no_assets_externos(self):
        self.assertIn('const BUS_AUDIO := &"Musica"', self.minicadena)
        self.assertIn("AudioStreamPlayer3D.new()", self.minicadena)
        self.assertIn("AudioStreamWAV.new()", self.minicadena)
        self.assertIn("func alternar_reproduccion", self.minicadena)
        self.assertIn("func cambiar_volumen", self.minicadena)
        self.assertIn("_sincronizar_audio(true)", self.minicadena)
        self.assertIn("if _audio.has_stream_playback():", self.minicadena)
        self.assertIn("_audio.stream_paused = true", self.minicadena)
        self.assertIn("_audio.stream_paused = false", self.minicadena)
        self.assertIn("const AUDIO_UNIT_SIZE := 1.5", self.minicadena)
        self.assertIn("const AUDIO_MAX_DISTANCE := 7.0", self.minicadena)
        self.assertIn("const AUDIO_PANNING_STRENGTH := 0.65", self.minicadena)
        self.assertIn(
            "attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE",
            self.minicadena,
        )
        self.assertNotIn("res://assets/audio/", self.minicadena)

    def test_casa_monta_la_minicadena_y_el_verificador_la_ejecuta(self):
        self.assertIn("MinicadenaDomestica98.new()", self.casa)
        self.assertIn("_montar_minicadena", self.casa)
        self.assertIn("pruebas/pruebas_radio_domestica_98.gd", self.verificador)


if __name__ == "__main__":
    unittest.main()
