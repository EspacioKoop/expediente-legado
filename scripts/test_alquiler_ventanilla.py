from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CAPA = RAIZ / "godot" / "guion" / "dia_alquiler_app.gd"
CAPA_GATO = RAIZ / "godot" / "guion" / "dia_gato_app.gd"
CAPA_ONBOARDING = RAIZ / "godot" / "guion" / "dia_onboarding_app.gd"
ESCENA_DIA = RAIZ / "godot" / "escenas" / "dia.tscn"


class VentanillaAlquilerTest(unittest.TestCase):
    def setUp(self):
        self.capa = CAPA.read_text(encoding="utf-8")
        self.capa_gato = CAPA_GATO.read_text(encoding="utf-8")
        self.capa_onboarding = CAPA_ONBOARDING.read_text(encoding="utf-8")
        self.escena = ESCENA_DIA.read_text(encoding="utf-8")

    def test_el_dia_activa_la_capa_de_alquiler(self):
        self.assertIn('path="res://guion/dia_onboarding_app.gd"', self.escena)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.capa_onboarding)
        self.assertIn('extends "res://guion/dia_alquiler_app.gd"', self.capa_gato)
        self.assertIn('extends "res://guion/dia_ascensor_app.gd"', self.capa)

    def test_solo_aparece_en_el_trayecto_del_vencimiento(self):
        self.assertIn('fase != "trayecto"', self.capa)
        self.assertIn("Jornada.alquiler_vencimiento(dia)", self.capa)
        self.assertIn("Jornada.alquiler_pendiente(jornada)", self.capa)
        self.assertIn('"destino": DESTINO_ALQUILER', self.capa)

    def test_reutiliza_la_misma_ventanilla(self):
        self.assertIn('"rotulo": "VENTANILLA_TITULO"', self.capa)
        self.assertNotIn("SALIDA_ALQUILER", self.capa)

    def test_el_pago_delega_en_jornada_y_se_guarda(self):
        pagar = self.capa.index("Jornada.pagar_alquiler(jornada)")
        guardar = self.capa.index('_guardar_o_avisar("")', pagar)
        self.assertLess(pagar, guardar)
        self.assertNotIn("PRECIO_ALQUILER =", self.capa)
        self.assertNotIn('jornada["dinero"] -=', self.capa)
        self.assertNotIn('jornada["acciones"] -=', self.capa)

    def test_el_mostrador_no_cambia_de_fase(self):
        self.assertNotIn('_entrar_en("alquiler")', self.capa)
        self.assertIn("_pagar_alquiler()", self.capa)
        self.assertIn("super._al_pisar_salida(cuerpo, salida)", self.capa)


if __name__ == "__main__":
    unittest.main()
