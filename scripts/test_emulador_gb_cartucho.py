from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
AUDIO_UI = ROOT / "godot" / "guion" / "emulador_portatil_audio_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "emulador_gb_textos.json"


class EmuladorGBCartuchoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.audio_ui = AUDIO_UI.read_text(encoding="utf-8")
        cls.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))

    def test_cambio_de_cartucho_tiene_tres_fases_breves(self):
        self.assertIn("DURACION_EXPULSION_CARTUCHO := 0.12", self.audio_ui)
        self.assertIn("DURACION_RANURA_VACIA := 0.06", self.audio_ui)
        self.assertIn("DURACION_INSERCION_CARTUCHO := 0.14", self.audio_ui)
        self.assertIn('"cartucho_expulsando"', self.audio_ui)
        self.assertIn('"cartucho_ranura_vacia"', self.audio_ui)
        self.assertIn('"cartucho_insertando"', self.audio_ui)
        self.assertIn("await _esperar_cambio_cartucho", self.audio_ui)

    def test_cambio_detiene_rom_y_guarda_sram_antes_de_expulsar(self):
        cuerpo = self.audio_ui.split("func _cargar_rom(ruta: String) -> void:", 1)[1].split(
            "func ", 1
        )[0]
        self.assertLess(cuerpo.index("_guardar_sram()"), cuerpo.index('_ruta_sram_actual = ""'))
        self.assertLess(cuerpo.index('_ruta_sram_actual = ""'), cuerpo.index("_jugando = false"))
        self.assertIn("_limpiar_audio_emulado()", cuerpo)
        self.assertIn("_cancelar_encendido()", cuerpo)

    def test_efectos_desactivados_mantienen_carga_inmediata(self):
        cuerpo = self.audio_ui.split("func _cargar_rom(ruta: String) -> void:", 1)[1].split(
            "func ", 1
        )[0]
        self.assertIn("if not _efectos_presentacion:", cuerpo)
        self.assertIn("super._cargar_rom(ruta)", cuerpo)
        cambio = self.audio_ui.split(
            "func _al_cambiar_efectos(activos: bool) -> void:", 1
        )[1].split("func ", 1)[0]
        self.assertIn("if activos or not _cambiando_cartucho:", cambio)
        self.assertIn("_cancelar_cambio_cartucho()", cambio)
        self.assertIn("super._cargar_rom(ruta)", cambio)

    def test_cartucho_visible_no_toca_nucleo_ni_estado_de_campana(self):
        self.assertIn('name = "EstadoCartuchoPortatil"', self.audio_ui)
        self.assertIn("_lista.move_child(_cartucho_visual, 0)", self.audio_ui)
        self.assertIn('super._cargar_rom(ruta)', self.audio_ui)
        for termino in ("Partida", "Jornada", "pistas_descubiertas", "dinero"):
            self.assertNotIn(termino, self.audio_ui)

    def test_textos_del_ritual_son_explicitos(self):
        self.assertEqual(self.textos["cartucho_ranura_vacia"], "Ranura de cartucho: vacía")
        self.assertIn("%s", self.textos["cartucho_insertado"])
        self.assertIn("%s", self.textos["cartucho_expulsando"])
        self.assertIn("%s", self.textos["cartucho_insertando"])


if __name__ == "__main__":
    unittest.main()
