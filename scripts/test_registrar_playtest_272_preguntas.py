from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_272 as playtest  # noqa: E402


class TestRegistrarPlaytest272Preguntas(unittest.TestCase):
    def test_preguntar_entrada_valida_directa(self):
        with patch("builtins.input", return_value="  Tester Alpha  "):
            respuesta = playtest.preguntar("Alias: ")
            self.assertEqual(respuesta, "Tester Alpha")

    def test_preguntar_repite_ante_entradas_vacias(self):
        respuestas_secuencia = ["", "   ", "Tester Beta"]
        with patch("builtins.input", side_effect=respuestas_secuencia), patch("builtins.print") as mock_print:
            respuesta = playtest.preguntar("Alias: ")
            self.assertEqual(respuesta, "Tester Beta")
            mock_print.assert_called_with("La respuesta no puede quedar vacía.")
            self.assertEqual(mock_print.call_count, 2)

    def test_preguntar_si_no_respuestas_afirmativas(self):
        opciones_afirmativas = ["s", "S", " si ", "SI", "sí", "SÍ"]
        for opcion in opciones_afirmativas:
            with self.subTest(opcion=opcion):
                with patch("builtins.input", return_value=opcion):
                    self.assertTrue(playtest.preguntar_si_no("¿Pregunta?"))

    def test_preguntar_si_no_respuestas_negativas(self):
        opciones_negativas = ["n", "N", " no ", "NO"]
        for opcion in opciones_negativas:
            with self.subTest(opcion=opcion):
                with patch("builtins.input", return_value=opcion):
                    self.assertFalse(playtest.preguntar_si_no("¿Pregunta?"))

    def test_preguntar_si_no_repite_ante_entradas_invalidas(self):
        secuencia = ["", "quizas", "tal vez", "s"]
        with patch("builtins.input", side_effect=secuencia), patch("builtins.print") as mock_print:
            resultado = playtest.preguntar_si_no("¿Entendido?")
            self.assertTrue(resultado)
            mock_print.assert_called_with("Responde s o n.")
            self.assertEqual(mock_print.call_count, 3)

    def test_recoger_datos_y_encadenar_evaluar_gate_y_render_markdown(self):
        # Secuencia simulada incluyendo reintentos en preguntar y preguntar_si_no
        secuencia_input = [
            # participante (con reintento vacío)
            "",
            "tester-272",
            # plataforma
            "Linux",
            # build_sha
            "git-sha-272",
            # conocimiento_previo (con reintento inválido)
            "invalido",
            "n",
            # respuestas literales
            "Archivo planta 4",
            "Terminal 4-B",
            "Abrir SIGA",
            "Puerta trasera",
            "Instrucción clara",
            # checks facilitador
            "s",  # espacio_identificado
            "s",  # puesto_identificado
            "s",  # primera_accion_identificada
            "s",  # salida_encontrada
            "s",  # tutorial_no_confundido
            "n",  # ayuda_externa
            "n",  # incidencia_bloqueante
            # opcionales
            "Ninguna incidencia",  # incidencia
            "Todo fluido",  # observaciones
        ]

        with patch("builtins.input", side_effect=secuencia_input), patch("builtins.print"):
            datos = playtest.recoger_datos()

        self.assertEqual(datos["participante"], "tester-272")
        self.assertEqual(datos["plataforma"], "Linux")
        self.assertEqual(datos["build_sha"], "git-sha-272")
        self.assertFalse(datos["conocimiento_previo"])
        self.assertEqual(datos["respuesta_espacio"], "Archivo planta 4")
        self.assertEqual(datos["respuesta_puesto"], "Terminal 4-B")
        self.assertEqual(datos["respuesta_accion"], "Abrir SIGA")
        self.assertEqual(datos["respuesta_salida"], "Puerta trasera")
        self.assertEqual(datos["respuesta_tutorial"], "Instrucción clara")
        self.assertTrue(datos["espacio_identificado"])
        self.assertTrue(datos["puesto_identificado"])
        self.assertTrue(datos["primera_accion_identificada"])
        self.assertTrue(datos["salida_encontrada"])
        self.assertTrue(datos["tutorial_no_confundido"])
        self.assertFalse(datos["ayuda_externa"])
        self.assertFalse(datos["incidencia_bloqueante"])
        self.assertEqual(datos["incidencia"], "Ninguna incidencia")
        self.assertEqual(datos["observaciones"], "Todo fluido")

        # Encadenamiento con evaluar_gate
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["issue_cerrable"])
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["sin_incidencia_bloqueante"])

        # Encadenamiento con render_markdown
        markdown = playtest.render_markdown(datos)
        self.assertIn("tester-272", markdown)
        self.assertIn("git-sha-272", markdown)
        self.assertIn("Archivo planta 4", markdown)
        self.assertIn("Ninguna incidencia", markdown)
        self.assertIn("Todo fluido", markdown)
        self.assertIn("#272 cerrable con esta evidencia: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
