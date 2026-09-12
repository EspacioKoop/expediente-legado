from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
POLITICA = ROOT / "godot" / "guion" / "gato_ayuda.gd"
AVATAR = ROOT / "godot" / "guion" / "gato_asistente_2d.gd"
CAPA = ROOT / "godot" / "guion" / "dia_gato_app.gd"
CAPA_ONBOARDING = ROOT / "godot" / "guion" / "dia_onboarding_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class GatoAyudaTest(unittest.TestCase):
    def setUp(self):
        self.politica = POLITICA.read_text(encoding="utf-8")
        self.avatar = AVATAR.read_text(encoding="utf-8")
        self.capa = CAPA.read_text(encoding="utf-8")
        self.capa_onboarding = CAPA_ONBOARDING.read_text(encoding="utf-8")
        self.escena = ESCENA.read_text(encoding="utf-8")

    def test_una_sola_fuente_de_estado(self):
        self.assertIn("class_name GatoAyuda", self.politica)
        self.assertIn('gato.get("presente", false)', self.politica)
        self.assertIn('gato.get("dias_sin_comer", 0)', self.politica)
        self.assertIn("GatoConducta.DIAS_PARA_DESCONFIAR", self.politica)
        self.assertNotIn("Partida", self.politica)
        self.assertNotIn('gato.get("afecto"', self.politica)
        self.assertNotIn('gato["afecto"]', self.politica)

    def test_asistente_degrada_sin_mentir_sobre_controles(self):
        self.assertIn('return ["VISOR_ELIJA", "ENTRADA_VOZ_SOLO"]', self.politica)
        self.assertIn('return ["VISOR_ELIJA"]', self.politica)
        self.assertIn("return []", self.politica)
        for clave in ("PUESTO_LEVANTARSE", "ARCHIVO_ERROR_GUARDAR", "A7_PRESENTAR"):
            self.assertNotIn(clave, self.politica)

    def test_hay_un_gato_2d_visible_tipo_ayudante_de_escritorio(self):
        self.assertIn("class_name GatoAsistente2D", self.avatar)
        self.assertIn("extends Control", self.avatar)
        self.assertIn("func _draw()", self.avatar)
        self.assertIn("draw_circle", self.avatar)
        self.assertIn("draw_colored_polygon", self.avatar)
        self.assertIn("GatoAsistente2D.new()", self.capa)
        self.assertNotIn("Sprite2D", self.avatar)
        self.assertNotIn("load(", self.avatar)

    def test_el_mismo_nivel_gobierna_el_guia(self):
        self.assertIn("static func guia_visible", self.politica)
        self.assertIn("static func guia_orienta", self.politica)
        self.assertIn("nivel(gato) != AUSENTE", self.politica)
        self.assertIn("nivel(gato) == COMPLETA", self.politica)

    def test_capa_no_duplica_estado_y_conserva_herencia(self):
        self.assertIn('extends "res://guion/dia_alquiler_app.gd"', self.capa)
        self.assertIn("GatoAyuda.lineas_asistente", self.capa)
        self.assertIn("GatoAyuda.guia_visible", self.capa)
        self.assertIn("GatoAyuda.guia_orienta", self.capa)
        self.assertIn("Gato.new()", self.capa)
        self.assertNotIn('jornada["gato"] =', self.capa)
        self.assertNotIn('jornada["gato"][', self.capa)

    def test_el_guia_orienta_sin_convertir_la_salida_en_marcador(self):
        self.assertIn('fase != "sueño"', self.capa)
        self.assertIn('espacio.get("salidas", [])', self.capa)
        self.assertIn("atan2(direccion.x, direccion.z)", self.capa)
        self.assertNotIn('"visible": true', self.capa)
        self.assertNotIn("Sueno.recordar", self.capa)

    def test_la_escena_activa_la_nueva_capa(self):
        self.assertIn('path="res://guion/dia_onboarding_app.gd"', self.escena)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.capa_onboarding)


if __name__ == "__main__":
    unittest.main()
