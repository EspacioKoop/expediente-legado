from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "dia_onboarding_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class OnboardingArchivoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.capa = CAPA.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_la_escena_activa_una_capa_fina_sobre_el_dia_existente(self):
        self.assertIn('res://guion/dia_onboarding_app.gd', self.escena)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.capa)

    def test_el_onboarding_se_limita_al_primer_arranque_sin_lecturas(self):
        self.assertIn('fase == "archivo"', self.capa)
        self.assertIn('jornada.get("dia", 0)) == 1', self.capa)
        self.assertIn('Jornada.ACCIONES_POR_DIA', self.capa)
        self.assertIn('jornada.get("leido_hoy", []).is_empty()', self.capa)

    def test_el_puesto_real_queda_destacado_sin_waypoint_permanente(self):
        self.assertIn('Vector3(-4.0, 1.45, 1.0)', self.capa)
        self.assertIn('OmniLight3D.new()', self.capa)
        self.assertIn('PUESTO 4-B · SIGA-98', self.capa)
        self.assertIn('terminal verde', self.capa)
        self.assertNotIn('Label3D', self.capa)
        self.assertNotIn('NavigationAgent', self.capa)

    def test_la_pista_solo_desaparece_si_siga_llega_a_abrirse(self):
        self.assertIn('func _abrir_expediente() -> void:', self.capa)
        self.assertIn('super._abrir_expediente()', self.capa)
        self.assertIn('if _pantalla != null:', self.capa)
        self.assertIn('_retirar_onboarding_archivo()', self.capa)


if __name__ == "__main__":
    unittest.main()
