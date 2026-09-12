from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CINEMATICA = RAIZ / "godot" / "guion" / "ascensor_cinematica.gd"
CAPA = RAIZ / "godot" / "guion" / "dia_ascensor_app.gd"
CAPA_ALQUILER = RAIZ / "godot" / "guion" / "dia_alquiler_app.gd"
CAPA_GATO = RAIZ / "godot" / "guion" / "dia_gato_app.gd"
CAPA_ONBOARDING = RAIZ / "godot" / "guion" / "dia_onboarding_app.gd"
ESCENA_DIA = RAIZ / "godot" / "escenas" / "dia.tscn"


class AscensorTest(unittest.TestCase):
    def setUp(self):
        self.cinematica = CINEMATICA.read_text(encoding="utf-8")
        self.capa = CAPA.read_text(encoding="utf-8")
        self.capa_alquiler = CAPA_ALQUILER.read_text(encoding="utf-8")
        self.capa_gato = CAPA_GATO.read_text(encoding="utf-8")
        self.capa_onboarding = CAPA_ONBOARDING.read_text(encoding="utf-8")
        self.escena = ESCENA_DIA.read_text(encoding="utf-8")

    def test_la_bajada_es_breve_y_tiene_remate(self):
        segundos = [float(valor) for valor in re.findall(r'"segundos":\s*([0-9.]+)', self.cinematica)]
        self.assertEqual(len(segundos), 3)
        self.assertLessEqual(sum(segundos), 3.5)
        self.assertIn('"nombre": "portal"', self.cinematica)

    def test_reutiliza_el_reproductor_comun(self):
        self.assertIn('const ID := "ascensor-bajada"', self.cinematica)
        self.assertIn("Cinematica.resolver", self.cinematica)
        self.assertIn("Cinematica.vistas_de", self.capa)

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
        self.assertIn('path="res://guion/dia_onboarding_app.gd"', self.escena)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.capa_onboarding)
        self.assertIn('extends "res://guion/dia_alquiler_app.gd"', self.capa_gato)
        self.assertIn('extends "res://guion/dia_ascensor_app.gd"', self.capa_alquiler)


if __name__ == "__main__":
    unittest.main()
