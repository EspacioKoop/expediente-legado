from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_281 as playtest  # noqa: E402


class TestRegistrarPlaytest281Preguntas(unittest.TestCase):
    @patch("builtins.input")
    def test_preguntar_respuesta_valida_directa(self, mock_input):
        mock_input.return_value = "  tester_01  "
        resultado = playtest.preguntar("Alias: ")
        self.assertEqual(resultado, "tester_01")
        mock_input.assert_called_once_with("Alias: ")

    @patch("builtins.input")
    def test_preguntar_reintenta_si_entrada_vacia_o_espacios(self, mock_input):
        mock_input.side_effect = ["", "   ", "\t", "usuario_valido"]
        resultado = playtest.preguntar("Alias: ")
        self.assertEqual(resultado, "usuario_valido")
        self.assertEqual(mock_input.call_count, 4)

    @patch("builtins.input")
    def test_preguntar_si_no_respuestas_afirmativas(self, mock_input):
        respuestas_afirmativas = ["s", "S", "si", "SI", "sí", "Sí", " SÍ "]
        for resp in respuestas_afirmativas:
            with self.subTest(respuesta=resp):
                mock_input.return_value = resp
                resultado = playtest.preguntar_si_no("¿Pregunta?")
                self.assertTrue(resultado)

    @patch("builtins.input")
    def test_preguntar_si_no_respuestas_negativas(self, mock_input):
        respuestas_negativas = ["n", "N", "no", "NO", " No "]
        for resp in respuestas_negativas:
            with self.subTest(respuesta=resp):
                mock_input.return_value = resp
                resultado = playtest.preguntar_si_no("¿Pregunta?")
                self.assertFalse(resultado)

    @patch("builtins.input")
    def test_preguntar_si_no_reintenta_hasta_respuesta_valida(self, mock_input):
        mock_input.side_effect = ["quizas", "", "123", "tal vez", "s"]
        resultado = playtest.preguntar_si_no("¿Pregunta?")
        self.assertTrue(resultado)
        self.assertEqual(mock_input.call_count, 5)

    @patch("builtins.input")
    def test_preguntar_segundos_valores_validos(self, mock_input):
        casos = [
            ("15.5", 15.5),
            ("12,3", 12.3),
            ("0", 0.0),
            (" 42.0 ", 42.0),
        ]
        for entrada, esperado in casos:
            with self.subTest(entrada=entrada):
                mock_input.return_value = entrada
                resultado = playtest.preguntar_segundos()
                self.assertEqual(resultado, esperado)

    @patch("builtins.input")
    def test_preguntar_segundos_reintenta_por_texto_o_negativo(self, mock_input):
        mock_input.side_effect = ["invalido", "-10", "-0.1", "abc", "25,5"]
        resultado = playtest.preguntar_segundos()
        self.assertEqual(resultado, 25.5)
        self.assertEqual(mock_input.call_count, 5)

    @patch("builtins.input")
    def test_recoger_datos_y_encadenado_con_evaluar_gate_y_render_markdown(self, mock_input):
        secuencia_inputs = [
            "",  # participante reintento
            "Tester-281",  # participante
            "Linux",  # plataforma
            "abc123sha",  # build_sha
            "Teclado/ratón",  # control
            "no_numero",  # primera_accion_segundos reintento
            "-5",  # primera_accion_segundos reintento
            "12,5",  # primera_accion_segundos
            "invalido",  # check 1 reintento
            "s",  # estado_0_2_visible
            "s",  # feedback_1_2_claro
            "s",  # gato_reorienta
            "s",  # reentrada_no_duplica
            "s",  # transicion_2_2
            "s",  # sin_salida_oculta
            "s",  # tiempo_no_ruta_normal
            "s",  # export_real
            "s",  # persistencia_reapertura
            "s",  # sin_incidencia_bloqueante
            "Ninguna",  # incidencia
            "Todo fluido",  # observaciones
        ]
        mock_input.side_effect = secuencia_inputs

        datos = playtest.recoger_datos()

        self.assertEqual(datos["participante"], "Tester-281")
        self.assertEqual(datos["plataforma"], "Linux")
        self.assertEqual(datos["build_sha"], "abc123sha")
        self.assertEqual(datos["control"], "Teclado/ratón")
        self.assertEqual(datos["primera_accion_segundos"], 12.5)
        self.assertTrue(datos["estado_0_2_visible"])
        self.assertTrue(datos["feedback_1_2_claro"])
        self.assertTrue(datos["gato_reorienta"])
        self.assertTrue(datos["reentrada_no_duplica"])
        self.assertTrue(datos["transicion_2_2"])
        self.assertTrue(datos["sin_salida_oculta"])
        self.assertTrue(datos["tiempo_no_ruta_normal"])
        self.assertTrue(datos["export_real"])
        self.assertTrue(datos["persistencia_reapertura"])
        self.assertTrue(datos["sin_incidencia_bloqueante"])
        self.assertEqual(datos["incidencia"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Todo fluido")
        self.assertIn("fecha", datos)

        # Encadenado con evaluar_gate
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["primera_accion_menos_60s"])
        self.assertTrue(gate["issue_cerrable"])

        # Encadenado con render_markdown
        markdown = playtest.render_markdown(datos)
        self.assertIn("participante: Tester-281", markdown)
        self.assertIn("build SHA: `abc123sha`", markdown)
        self.assertIn("primera acción válida: 12.5 s", markdown)
        self.assertIn("#281 cerrable con esta evidencia: **SÍ**", markdown)
        self.assertIn("Ninguna", markdown)
        self.assertIn("Todo fluido", markdown)


if __name__ == "__main__":
    unittest.main()
