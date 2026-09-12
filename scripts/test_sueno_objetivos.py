from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
REGLA = ROOT / "godot" / "guion" / "sueno_objetivos.gd"
GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
ONBOARDING = ROOT / "godot" / "guion" / "dia_onboarding_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class SuenoObjetivosTest(unittest.TestCase):
    def setUp(self):
        self.regla = REGLA.read_text(encoding="utf-8")
        self.gato = GATO.read_text(encoding="utf-8")
        self.onboarding = ONBOARDING.read_text(encoding="utf-8")
        self.escena = ESCENA.read_text(encoding="utf-8")

    def test_vertical_tres_objetivos_dos_requeridos(self):
        self.assertIn("POSIBLES_PRIMER_CORTE := 3", self.regla)
        self.assertIn("REQUERIDOS_PRIMER_CORTE := 2", self.regla)
        self.assertIn('"completados": []', self.regla)
        self.assertIn('completados.has(id)', self.regla)
        self.assertIn('estado["resuelto"] = true', self.regla)

    def test_el_sueno_ya_no_monta_la_salida_como_progreso_normal(self):
        self.assertIn('espacio["salidas"] = []', self.gato)
        self.assertIn("_montar_objetivos_sueno", self.gato)
        self.assertIn('zona.set_meta("objetivo"', self.gato)
        self.assertIn("_al_pisar_objetivo", self.gato)

    def test_segundo_objetivo_resuelve_y_transiciona(self):
        self.assertIn("SuenoObjetivos.resuelto(estado)", self.gato)
        self.assertIn('jornada["sueno_escenas"].pop_front()', self.gato)
        self.assertIn("Jornada.despertar(jornada)", self.gato)
        self.assertIn('_entrar_en(destino)', self.gato)

    def test_el_gato_apunta_a_objetivo_y_no_a_puerta(self):
        self.assertIn('extends "res://guion/dia_alquiler_app.gd"', self.gato)
        self.assertIn('espacio.get("salidas", [])', self.gato)
        self.assertIn('_salida_guia = _objetivos_espacio[0].get("pos", _entrada_guia)', self.gato)
        self.assertIn("_hay_rumbo_guia = true", self.gato)

    def test_la_escena_conserva_la_capa_raiz_del_gato(self):
        self.assertIn('path="res://guion/dia_onboarding_app.gd"', self.escena)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.onboarding)


if __name__ == "__main__":
    unittest.main()
