"""Regresión estructural del objetivo contextual tras el playtest #2597.

No sustituye la captura real en Godot; fija solo contratos clave de integración.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CODE = (ROOT / "godot/guion/dia_onboarding_app.gd").read_text(encoding="utf-8")


class GuiaContextualTest(unittest.TestCase):
    def test_reutiliza_cadena_y_proceso_base(self):
        self.assertIn('extends "res://guion/dia_gato_app.gd"', CODE)
        self.assertIsNotNone(re.search(r"func _process\(_delta: float\).*?super\(_delta\)", CODE, re.S))

    def test_panel_inicial_con_ancho_y_tipografia(self):
        self.assertIn("_pista_puesto.offset_left = -450", CODE)
        self.assertIn("_pista_puesto.offset_right = 450", CODE)
        self.assertIn("texto.custom_minimum_size.x = 820", CODE)
        self.assertIn('rol.add_theme_font_size_override("font_size", 28)', CODE)
        self.assertIn('texto.add_theme_font_size_override("font_size", 24)', CODE)

    def test_el_objetivo_persiste_en_todas_las_fases(self):
        for fase in ('"archivo":', '"trayecto":', '"casa":', '"sueño":'):
            self.assertIn(fase, CODE)
        self.assertIn('func _consejo_de_fase() -> String:', CODE)
        self.assertIn('func _montar_guia_fase() -> void:', CODE)

    def test_instrucciones_muestran_accion_y_controles(self):
        for pista in ("SIGA-98", "WASD", "Interactuar: E", "FIN DE TURNO"):
            self.assertIn(pista, CODE)

    def test_indicaciones_se_refrescan_en_cambios_de_progreso(self):
        self.assertIn('_segundos_hasta_guia = 0.25', CODE)
        self.assertIn('_ultimo_consejo != consejo', CODE)
        self.assertIn('_refrescar_guia_fase()', CODE)

    def test_no_estorbar_al_modal_de_expediente(self):
        self.assertIn('_pantalla == null', CODE)
        self.assertIn('not is_instance_valid(_pista_puesto)', CODE)
        self.assertIsNotNone(re.search(r"func _abrir_expediente\(\).*?_retirar_onboarding_archivo\(\).*?_refrescar_guia_fase\(\)", CODE, re.S))

    def test_texto_legible_con_ancho_real_en_banda_lateral(self):
        self.assertIn('offset_left = -644', CODE)
        self.assertIn('offset_right = -24', CODE)
        self.assertIn('_texto_guia_fase.custom_minimum_size.x = 575', CODE)
        self.assertIn('add_theme_font_size_override("font_size", 23)', CODE)
        self.assertIn("Control.PRESET_TOP_RIGHT", CODE)

    def test_consejo_no_modifica_partida_ni_guarda_progreso(self):
        fn = CODE.split("func _consejo_de_fase() -> String:", 1)[1].split("\n\nfunc ", 1)[0]
        for forbidden in ("partida.estado[", "Jornada.", "_guardar_o_avisar", "_entrar_en("):
            self.assertNotIn(forbidden, fn)


if __name__ == "__main__":
    unittest.main()
