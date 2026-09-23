from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CINEMATICA = RAIZ / "godot" / "guion" / "ascensor_cinematica.gd"
APP_3D = RAIZ / "godot" / "guion" / "ascensor_3d_app.gd"
ESCENA_ASCENSOR = RAIZ / "godot" / "escenas" / "ascensor_3d.tscn"
CAPA = RAIZ / "godot" / "guion" / "dia_ascensor_app.gd"
CAPA_ALQUILER = RAIZ / "godot" / "guion" / "dia_alquiler_app.gd"
CAPA_TRABAJILLOS = RAIZ / "godot" / "guion" / "dia_trabajillos_app.gd"
CAPA_GATO = RAIZ / "godot" / "guion" / "dia_gato_app.gd"
CAPA_ONBOARDING = RAIZ / "godot" / "guion" / "dia_onboarding_app.gd"
CAPA_CLIMA = RAIZ / "godot" / "guion" / "dia_clima_app.gd"
ESCENA_DIA = RAIZ / "godot" / "escenas" / "dia.tscn"


class AscensorTest(unittest.TestCase):
    def setUp(self):
        self.cinematica = CINEMATICA.read_text(encoding="utf-8")
        self.app_3d = APP_3D.read_text(encoding="utf-8")
        self.escena_ascensor = ESCENA_ASCENSOR.read_text(encoding="utf-8")
        self.capa = CAPA.read_text(encoding="utf-8")
        self.capa_alquiler = CAPA_ALQUILER.read_text(encoding="utf-8")
        self.capa_trabajillos = CAPA_TRABAJILLOS.read_text(encoding="utf-8")
        self.capa_gato = CAPA_GATO.read_text(encoding="utf-8")
        self.capa_onboarding = CAPA_ONBOARDING.read_text(encoding="utf-8")
        self.capa_clima = CAPA_CLIMA.read_text(encoding="utf-8")
        self.escena = ESCENA_DIA.read_text(encoding="utf-8")

    def test_la_bajada_es_breve_y_tiene_remate(self):
        segundos = [float(valor) for valor in re.findall(r'"segundos":\s*([0-9.]+)', self.cinematica)]
        self.assertEqual(len(segundos), 3)
        self.assertGreaterEqual(sum(segundos), 4.0)
        self.assertLessEqual(sum(segundos), 5.0)
        self.assertIn('"nombre": "salida-archivo"', self.cinematica)
        self.assertIn('"nombre": "portal"', self.cinematica)

    def test_la_presentacion_ya_no_es_placeholder_2d(self):
        self.assertEqual(self.cinematica.count('"tipo": "3d"'), 3)
        self.assertNotIn('"tipo": "2d"', self.cinematica)
        self.assertNotIn('"figura"', self.cinematica)
        self.assertIn('"camara": ORIGEN + Vector3', self.cinematica)
        self.assertIn('"mira": ORIGEN + Vector3', self.cinematica)
        self.assertEqual(self.cinematica.count('"camara_desde": ORIGEN + Vector3'), 3)
        self.assertEqual(self.cinematica.count('"mira_desde": ORIGEN + Vector3'), 3)

    def test_cabina_3d_tiene_volumen_panel_y_apertura(self):
        self.assertIn('extends "res://guion/cinematica_app.gd"', self.app_3d)
        self.assertIn("BoxMesh.new()", self.app_3d)
        self.assertIn("OmniLight3D.new()", self.app_3d)
        self.assertIn('"PuertaIzquierda"', self.app_3d)
        self.assertIn('"PuertaDerecha"', self.app_3d)
        self.assertIn("for i in 5:", self.app_3d)
        self.assertIn("plano_entrado.connect(_al_entrar_plano)", self.app_3d)
        self.assertIn("func _abrir_puertas()", self.app_3d)
        self.assertIn('tween_property(_puerta_izquierda, "position:x"', self.app_3d)
        self.assertIn('tween_property(_puerta_derecha, "position:x"', self.app_3d)

    def test_puertas_y_bajada_tienen_acentos_fisicos(self):
        self.assertIn('Sonido.sonar(self, "puerta_cierra")', self.app_3d)
        self.assertIn('Sonido.sonar(self, "puerta_abre")', self.app_3d)
        self.assertIn('Sonido.sonar(self, "marcar", 0.88)', self.app_3d)
        self.assertNotIn("AudioStreamPlayer.new()", self.app_3d)

    def test_salida_conserva_referentes_del_archivo_hasta_cerrar_puertas(self):
        self.assertIn('"salida-archivo"', self.app_3d)
        self.assertIn("_mostrar_planta4()", self.app_3d)
        self.assertIn("_abrir_puertas_inmediato()", self.app_3d)
        self.assertIn("espera.tween_callback(_cerrar_puertas_animado)", self.app_3d)
        self.assertIn('"desk"', self.app_3d)
        self.assertIn('"computerScreen"', self.app_3d)
        self.assertIn('"bookcaseClosed"', self.app_3d)
        self.assertIn("Modelos.mueble", self.app_3d)
        self.assertIn("_salida_exterior.visible = false", self.app_3d)
        self.assertIn("_salida_exterior.visible = true", self.app_3d)

    def test_escena_especializada_se_usa_en_lugar_del_lienzo_generico(self):
        self.assertIn('path="res://guion/ascensor_3d_app.gd"', self.escena_ascensor)
        self.assertIn('preload("res://escenas/ascensor_3d.tscn")', self.capa)
        self.assertNotIn('preload("res://escenas/cinematica.tscn")', self.capa)

    def test_reutiliza_el_reproductor_comun(self):
        self.assertIn('const ID := "ascensor-bajada"', self.cinematica)
        self.assertIn("Cinematica.resolver", self.cinematica)
        self.assertIn("Cinematica.vistas_de", self.capa)
        self.assertIn('extends "res://guion/cinematica_app.gd"', self.app_3d)

    def test_el_encuentro_del_ascensor_es_unico_y_reutiliza_al_cunado(self):
        self.assertIn("if vistas == 0:", self.cinematica)
        self.assertIn('plano["encuentro_companero"] = "cunado"', self.cinematica)
        self.assertIn("Companeros.frase_de(Companeros.CUNADO, 1)", self.cinematica)
        self.assertIn('_companero_encuentro.name = "EncuentroCunado"', self.app_3d)
        self.assertIn("Companeros.cuerpo_de(Companeros.CUNADO)", self.app_3d)
        self.assertIn('String(plano.get("encuentro_companero", "")) == "cunado"', self.app_3d)
        self.assertNotIn("cinematicas_vistas", self.app_3d)

    def test_solo_intercepta_archivo_hacia_trayecto(self):
        self.assertIn('jornada.get("fase", "") == "archivo"', self.capa)
        self.assertIn('String(salida.get_meta("destino", "")) == "trayecto"', self.capa)
        self.assertIn("super._al_pisar_salida(cuerpo, salida)", self.capa)

    def test_la_regla_y_el_guardado_ocurren_antes_de_la_pelicula(self):
        fichar = self.capa.index("Jornada.fichar_salida(jornada)")
        destino = self.capa.index('_entrar_en("trayecto")', fichar)
        guardar = self.capa.index('if not _guardar_o_avisar(""):', destino)
        reproducir = self.capa.index("_ascensor.reproducir(", guardar)
        self.assertLess(fichar, destino)
        self.assertLess(destino, guardar)
        self.assertLess(guardar, reproducir)

    def test_la_capa_no_aplica_otras_reglas_de_jornada(self):
        for llamada in (
            "Jornada.dormir(",
            "Jornada.despertar(",
            "Jornada.despertar_de_golpe(",
            "Jornada.perder_vida(",
        ):
            self.assertNotIn(llamada, self.capa)

    def test_el_dia_conserva_el_ascensor_por_herencia(self):
        self.assertIn('path="res://guion/dia_clima_app.gd"', self.escena)
        self.assertIn('extends "res://guion/dia_calle_app.gd"', self.capa_clima)
        calle = (RAIZ / "godot/guion/dia_calle_app.gd").read_text(encoding="utf-8")
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', calle)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.capa_onboarding)
        self.assertIn('extends "res://guion/dia_trabajillos_app.gd"', self.capa_gato)
        self.assertIn('extends "res://guion/dia_alquiler_app.gd"', self.capa_trabajillos)
        self.assertIn('extends "res://guion/dia_ascensor_app.gd"', self.capa_alquiler)


if __name__ == "__main__":
    unittest.main()
