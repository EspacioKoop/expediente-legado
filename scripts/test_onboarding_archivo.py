from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "dia_onboarding_app.gd"
CAPA_CLIMA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class OnboardingArchivoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.capa = CAPA.read_text(encoding="utf-8")
        cls.capa_clima = CAPA_CLIMA.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")

    def test_la_escena_activa_una_capa_fina_sobre_el_dia_existente(self):
        self.assertIn('path="res://guion/dia_clima_app.gd"', self.escena)
        self.assertIn('extends "res://guion/dia_calle_app.gd"', self.capa_clima)
        calle = (ROOT / "godot/guion/dia_calle_app.gd").read_text(encoding="utf-8")
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', calle)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.capa)

    def test_el_onboarding_se_limita_al_primer_arranque_sin_lecturas(self):
        self.assertIn('fase == "archivo"', self.capa)
        self.assertIn('jornada.get("dia", 0)) == 1', self.capa)
        self.assertIn('Jornada.ACCIONES_POR_DIA', self.capa)
        self.assertIn('jornada.get("leido_hoy", []).is_empty()', self.capa)

    def test_el_puesto_real_queda_destacado_sin_waypoint_permanente(self):
        self.assertIn('Vector3(-4.0, 1.45, 1.0)', self.capa)
        self.assertIn('OmniLight3D.new()', self.capa)
        self.assertIn('"ONBOARDING_PUESTO_SIGA"', self.capa)
        self.assertIn('"ONBOARDING_ACCION_SIGA"', self.capa)
        self.assertIn("PUESTO 4-B · SIGA-98", self.textos)
        self.assertIn("terminal verde", self.textos)
        self.assertNotIn('Label3D', self.capa)
        self.assertNotIn('NavigationAgent', self.capa)

    def test_el_objetivo_es_una_superficie_tutorial_inequivoca(self):
        self.assertIn('"ONBOARDING_OBJETIVO_INICIAL"', self.capa)
        self.assertIn('"ONBOARDING_PUESTO_SIGA"', self.capa)
        self.assertIn('"ONBOARDING_ACCION_SIGA"', self.capa)
        self.assertIn("rol.text = tr(CLAVE_ROL_ONBOARDING)", self.capa)
        self.assertIn(
            'texto.text = "%s\\n%s" % [tr(CLAVE_PUESTO_ONBOARDING), tr(CLAVE_ACCION_ONBOARDING)]',
            self.capa,
        )
        self.assertIn("Control.PRESET_CENTER_TOP", self.capa)
        self.assertIn("HUDEstilo.caja_tutorial()", self.capa)
        self.assertIn("HUDEstilo.TITULO_TUTORIAL", self.capa)
        self.assertIn("HUDEstilo.TEXTO_TUTORIAL", self.capa)
        self.assertNotIn("Control.PRESET_CENTER_BOTTOM", self.capa)
        self.assertNotIn('rol.text = "OBJETIVO INICIAL"', self.capa)
        self.assertNotIn("Mayús corre", self.capa)
        self.assertNotIn("Ctrl agacha", self.capa)
        self.assertNotIn("Espacio salta", self.capa)

    def test_el_tutorial_vive_en_el_arbitro_comun_del_hud(self):
        self.assertIn(
            "_pista_puesto.reparent(_hud_prioridades, false)", self.capa_clima
        )
        self.assertIn(
            "_hud_prioridades.registrar(HUDLayer.TUTORIAL, _pista_puesto)",
            self.capa_clima,
        )
        self.assertIn(
            "_hud_prioridades.activar(HUDLayer.TUTORIAL)", self.capa_clima
        )
        self.assertIn(
            "_hud_prioridades.desactivar(HUDLayer.TUTORIAL)", self.capa_clima
        )

    def test_la_pista_solo_desaparece_si_siga_llega_a_abrirse(self):
        self.assertIn('func _abrir_expediente() -> void:', self.capa)
        self.assertIn('super._abrir_expediente()', self.capa)
        self.assertIn('if _pantalla != null:', self.capa)
        self.assertIn('_retirar_onboarding_archivo()', self.capa)


if __name__ == "__main__":
    unittest.main()
