#!/usr/bin/env python3
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_780 as playtest  # noqa: E402


class PreguntasPlaytest780Test(unittest.TestCase):
    @patch("builtins.input", side_effect=["", "  ", " Tester 780 "])
    def test_preguntar_repite_si_vacio_y_recorta_espacios(self, _mock_input):
        resultado = playtest.preguntar("Nombre: ")
        self.assertEqual(resultado, "Tester 780")

    @patch("builtins.input", side_effect=["invalid", "tal vez", "s"])
    def test_preguntar_si_no_acepta_afirmativo_tras_reintentos(self, _mock_input):
        self.assertTrue(playtest.preguntar_si_no("¿Continuar?"))

    @patch("builtins.input")
    def test_preguntar_si_no_variaciones_validas(self, mock_input):
        mock_input.side_effect = ["SÍ"]
        self.assertTrue(playtest.preguntar_si_no("¿Pregunta 1?"))

        mock_input.side_effect = ["si"]
        self.assertTrue(playtest.preguntar_si_no("¿Pregunta 2?"))

        mock_input.side_effect = ["NO"]
        self.assertFalse(playtest.preguntar_si_no("¿Pregunta 3?"))

        mock_input.side_effect = ["n"]
        self.assertFalse(playtest.preguntar_si_no("¿Pregunta 4?"))

    @patch("builtins.input")
    def test_recoger_datos_cadena_evaluar_gate_y_render_markdown(self, mock_input):
        respuestas = [
            # Iniciales (con repetición por input vacío en tester e inválido en teclado_real)
            "",
            "Tester Juan",  # tester
            "Linux Ubuntu",  # plataforma
            "abc1234",  # build_sha
            "1920x1080",  # viewport
            "invalid_s_n",
            "s",  # teclado_real
            "s",  # mando_fisico
            "DualSense",  # mando_modelo
            # Creador
            "s",  # texto_pequeno_legible
            "s",  # ui_consistente
            "s",  # sin_recortes
            "captura_creador.png",  # captura
            "Sin notas",  # notas
            # Visor
            "s",  # titulo_jerarquizado
            "s",  # cuerpo_documental_legible
            "s",  # scroll_sin_recortes
            "captura_visor.png",  # captura
            "",  # notas
            # Reconstruccion
            "s",  # titulo_jerarquizado
            "s",  # foco_teclado_ok
            "s",  # foco_mando_ok
            "captura_reconstruccion.png",  # captura
            "OK",  # notas
            # Ventanilla
            "s",  # titulo_jerarquizado
            "s",  # replica_mono_legible
            "s",  # foco_teclado_ok
            "s",  # foco_mando_ok
            "captura_ventanilla.png",  # captura
            "",  # notas
            # Cierre
            "Ninguna",  # incidencias
            "Todo correcto",  # observaciones
        ]
        mock_input.side_effect = respuestas

        datos = playtest.recoger_datos()

        self.assertEqual(datos["tester"], "Tester Juan")
        self.assertEqual(datos["plataforma"], "Linux Ubuntu")
        self.assertEqual(datos["build_sha"], "abc1234")
        self.assertEqual(datos["viewport"], "1920x1080")
        self.assertTrue(datos["teclado_real"])
        self.assertTrue(datos["mando_fisico"])
        self.assertEqual(datos["mando_modelo"], "DualSense")
        self.assertEqual(datos["incidencias"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Todo correcto")

        # Encadenar evaluar_gate
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["viewport_ok"])
        self.assertTrue(gate["dispositivos_ok"])
        self.assertTrue(gate["pantallas_ok"])
        self.assertTrue(gate["capturas_ok"])
        self.assertTrue(gate["listo_para_cerrar"])

        # Encadenar render_markdown
        markdown = playtest.render_markdown(datos)
        self.assertIn("# Registro de playtest tipográfico · #780", markdown)
        self.assertIn("tester/facilitador: Tester Juan", markdown)
        self.assertIn("build SHA: `abc1234`", markdown)
        self.assertIn("captura_creador.png", markdown)
        self.assertIn("captura_visor.png", markdown)
        self.assertIn("listo para valorar cierre de #780: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
