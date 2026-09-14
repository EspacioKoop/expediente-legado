from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
POLITICA = ROOT / "godot" / "guion" / "gato_ayuda.gd"
AVATAR = ROOT / "godot" / "guion" / "gato_asistente_2d.gd"
CAPA = ROOT / "godot" / "guion" / "dia_gato_app.gd"
CAPA_TRABAJILLOS = ROOT / "godot" / "guion" / "dia_trabajillos_app.gd"
CAPA_ONBOARDING = ROOT / "godot" / "guion" / "dia_onboarding_app.gd"
CAPA_CLIMA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class GatoAyudaTest(unittest.TestCase):
    def setUp(self):
        self.politica = POLITICA.read_text(encoding="utf-8")
        self.avatar = AVATAR.read_text(encoding="utf-8")
        self.capa = CAPA.read_text(encoding="utf-8")
        self.capa_trabajillos = CAPA_TRABAJILLOS.read_text(encoding="utf-8")
        self.capa_onboarding = CAPA_ONBOARDING.read_text(encoding="utf-8")
        self.capa_clima = CAPA_CLIMA.read_text(encoding="utf-8")
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

    def test_contexto_siga_recupera_categorias_historicas_sin_estado_nuevo(self):
        self.assertIn("static func contexto_siga", self.politica)
        for contexto in (
            "CONTEXTO_EXPLORAR",
            "CONTEXTO_LISTO",
            "CONTEXTO_CERRADO",
            "CONTEXTO_DESCUBRIMIENTO",
            "CONTEXTO_COMBINACION_FALLIDA",
            "CONTEXTO_COMBINACION_REPETIDA",
        ):
            self.assertIn(contexto, self.politica)
        self.assertIn('estado.get("cerrado", false)', self.politica)
        self.assertIn('estado.get("listo_para_imputar", false)', self.politica)
        self.assertIn("EVENTO_A_CONTEXTO.has(evento)", self.politica)
        self.assertNotIn('estado["contexto_gato"] =', self.politica)
        self.assertNotIn('gato["contexto"] =', self.politica)

    def test_contexto_tiene_comentarios_distintos_y_hambre_no_los_muestra(self):
        claves = (
            "GATO_SIGA_EXPLORAR",
            "GATO_SIGA_LISTO",
            "GATO_SIGA_CERRADO",
            "GATO_SIGA_DESCUBRIMIENTO",
            "GATO_SIGA_COMBINACION_FALLIDA",
            "GATO_SIGA_COMBINACION_REPETIDA",
        )
        for clave in claves:
            self.assertEqual(self.politica.count(f'"{clave}"'), 1)
        self.assertIn("static func comentario_contextual", self.politica)
        self.assertIn("if contexto.is_empty():", self.politica)
        self.assertIn("var comentario := comentario_contextual(contexto)", self.politica)
        self.assertIn("lineas.append(comentario)", self.politica)
        # ESCASA conserva únicamente la instrucción necesaria y AUSENTE calla.
        self.assertGreaterEqual(self.politica.count('return ["VISOR_ELIJA"]'), 2)
        self.assertGreaterEqual(self.politica.count("return []"), 2)

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
        self.assertIn('extends "res://guion/dia_trabajillos_app.gd"', self.capa)
        self.assertIn('extends "res://guion/dia_alquiler_app.gd"', self.capa_trabajillos)
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
        self.assertIn('path="res://guion/dia_clima_app.gd"', self.escena)
        self.assertIn('extends "res://guion/dia_calle_app.gd"', self.capa_clima)
        calle = (ROOT / "godot/guion/dia_calle_app.gd").read_text(encoding="utf-8")
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', calle)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.capa_onboarding)


if __name__ == "__main__":
    unittest.main()
