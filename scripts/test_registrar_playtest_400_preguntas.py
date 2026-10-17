#!/usr/bin/env python3
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_400 as playtest  # noqa: E402


class TestRegistrarPlaytest400Preguntas(unittest.TestCase):
    @patch("builtins.input")
    def test_preguntar_respuesta_valida_directa(self, mock_input):
        mock_input.return_value = "  tester_400  "
        resultado = playtest.preguntar("Alias: ")
        self.assertEqual(resultado, "tester_400")
        mock_input.assert_called_once_with("Alias: ")

    @patch("builtins.input")
    def test_preguntar_reitera_si_entrada_vacia_o_espacios(self, mock_input):
        mock_input.side_effect = ["", "   ", "\t", "participante_valido"]
        resultado = playtest.preguntar("Alias: ")
        self.assertEqual(resultado, "participante_valido")
        self.assertEqual(mock_input.call_count, 4)

    @patch("builtins.input")
    def test_preguntar_si_no_respuestas_afirmativas(self, mock_input):
        for resp in ["s", "S", "si", "SI", "sí", "Sí", " SÍ "]:
            with self.subTest(respuesta=resp):
                mock_input.return_value = resp
                resultado = playtest.preguntar_si_no("¿Pregunta?")
                self.assertTrue(resultado)

    @patch("builtins.input")
    def test_preguntar_si_no_respuestas_negativas(self, mock_input):
        for resp in ["n", "N", "no", "NO", " No "]:
            with self.subTest(respuesta=resp):
                mock_input.return_value = resp
                resultado = playtest.preguntar_si_no("¿Pregunta?")
                self.assertFalse(resultado)

    @patch("builtins.input")
    def test_preguntar_si_no_reintenta_hasta_respuesta_valida(self, mock_input):
        mock_input.side_effect = ["quizas", "", "123", "tal vez", "n"]
        resultado = playtest.preguntar_si_no("¿Pregunta?")
        self.assertFalse(resultado)
        self.assertEqual(mock_input.call_count, 5)

    @patch("builtins.input")
    def test_preguntar_entero_valores_validos(self, mock_input):
        casos = [
            ("0", 0, 0),
            (" 5 ", 0, 5),
            ("2", 2, 2),
            ("10", 3, 10),
        ]
        for entrada, minimo, esperado in casos:
            with self.subTest(entrada=entrada, minimo=minimo):
                mock_input.return_value = entrada
                resultado = playtest.preguntar_entero("Numero: ", minimo=minimo)
                self.assertEqual(resultado, esperado)

    @patch("builtins.input")
    def test_preguntar_entero_reintenta_por_texto_o_menor_que_minimo(self, mock_input):
        mock_input.side_effect = ["abc", "-1", "1", "3"]
        resultado = playtest.preguntar_entero("Numero: ", minimo=2)
        self.assertEqual(resultado, 3)
        self.assertEqual(mock_input.call_count, 4)

    @patch("builtins.input")
    def test_recoger_datos_y_encadenado_con_evaluar_gate_y_render_markdown(self, mock_input):
        secuencia_inputs = [
            # participante (con reintento por cadena vacía)
            "",
            " Tester 400 ",
            # plataforma
            "Linux x86_64",
            # build_sha
            "sha_build_123",
            # evidencia_sha
            "sha_build_123",
            # conocimiento_previo (con reintento por respuesta inválida)
            "quizas",
            "n",
            # respuesta_oficina
            "Probé carpetas y reaccionaron.",
            # interacciones_oficina (con reintento por número menor a mínimo)
            "-1",
            "3",
            # respuesta_calle
            "Vi señales y semáforos responder.",
            # interacciones_calle
            "2",
            # respuesta_casa
            "Usé la radio y las luces.",
            # interacciones_casa
            "3",
            # respuesta_sueno
            "Las sombras reaccionaron a la lámpara.",
            # interacciones_sueno
            "2",
            # respuesta_general
            "Los escenarios reaccionaron adecuadamente.",
            # feedback_inmediato
            "s",
            # affordances_enganosas
            "n",
            # ayuda_directa
            "n",
            # incidencia_reproducible
            "n",
            # incidencia
            "Ninguna",
            # observaciones
            "Todo correcto.",
        ]
        mock_input.side_effect = secuencia_inputs

        datos = playtest.recoger_datos()

        self.assertEqual(datos["participante"], "Tester 400")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "sha_build_123")
        self.assertEqual(datos["evidencia_sha"], "sha_build_123")
        self.assertFalse(datos["conocimiento_previo"])
        self.assertEqual(datos["respuesta_oficina"], "Probé carpetas y reaccionaron.")
        self.assertEqual(datos["interacciones_oficina"], 3)
        self.assertEqual(datos["respuesta_calle"], "Vi señales y semáforos responder.")
        self.assertEqual(datos["interacciones_calle"], 2)
        self.assertEqual(datos["respuesta_casa"], "Usé la radio y las luces.")
        self.assertEqual(datos["interacciones_casa"], 3)
        self.assertEqual(datos["respuesta_sueno"], "Las sombras reaccionaron a la lámpara.")
        self.assertEqual(datos["interacciones_sueno"], 2)
        self.assertEqual(datos["respuesta_general"], "Los escenarios reaccionaron adecuadamente.")
        self.assertTrue(datos["feedback_inmediato"])
        self.assertFalse(datos["affordances_enganosas"])
        self.assertFalse(datos["ayuda_directa"])
        self.assertFalse(datos["incidencia_reproducible"])
        self.assertEqual(datos["incidencia"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Todo correcto.")
        self.assertIn("fecha", datos)

        # Encadenado con evaluar_gate
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["evidencia_misma_build"])
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["oficina_reactiva"])
        self.assertTrue(gate["calle_reactiva"])
        self.assertTrue(gate["casa_reactiva"])
        self.assertTrue(gate["sueno_reactivo"])
        self.assertTrue(gate["feedback_inmediato"])
        self.assertTrue(gate["sin_affordances_enganosas"])
        self.assertTrue(gate["sin_ayuda_directa"])
        self.assertTrue(gate["sin_incidencia"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

        # Encadenado con render_markdown
        markdown = playtest.render_markdown(datos)
        self.assertIn("participante: Tester 400", markdown)
        self.assertIn("build SHA: `sha_build_123`", markdown)
        self.assertIn("evidencia densidad #282 SHA: `sha_build_123`", markdown)
        self.assertIn("listo para valorar cierre de #400: **SÍ**", markdown)
        self.assertIn("Ninguna", markdown)
        self.assertIn("Todo correcto.", markdown)


if __name__ == "__main__":
    unittest.main()
