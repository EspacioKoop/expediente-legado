#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de preguntas y recolección de datos de registrar_playtest_156.py."""

import io
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
SCRIPTS_DIR = ROOT / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import registrar_playtest_156 as mod


class TestPreguntar(unittest.TestCase):
    """Pruebas para preguntar(prompt)."""

    @patch("builtins.input", side_effect=["  Tester Alpha  "])
    def test_preguntar_respuesta_valida_directa(self, mock_input) -> None:
        resultado = mod.preguntar("Alias: ")
        self.assertEqual(resultado, "Tester Alpha")
        mock_input.assert_called_once_with("Alias: ")

    @patch("builtins.input", side_effect=["", "   ", "\t", "  Jugador 1  "])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_preguntar_repite_si_vacio(self, mock_stdout, mock_input) -> None:
        resultado = mod.preguntar("Alias: ")
        self.assertEqual(resultado, "Jugador 1")
        self.assertEqual(mock_input.call_count, 4)
        salida = mock_stdout.getvalue()
        self.assertEqual(
            salida.count("La respuesta no puede quedar vacía.\n"),
            3,
        )


class TestPreguntarSiNo(unittest.TestCase):
    """Pruebas para preguntar_si_no(prompt)."""

    def test_preguntar_si_no_respuestas_afirmativas(self) -> None:
        respuestas = ["s", "si", "sí", "S", "Si", "SÍ", " s "]
        for resp in respuestas:
            with self.subTest(respuesta=resp):
                with patch("builtins.input", return_value=resp):
                    self.assertTrue(mod.preguntar_si_no("¿Pregunta?"))

    def test_preguntar_si_no_respuestas_negativas(self) -> None:
        respuestas = ["n", "no", "N", "NO", " n "]
        for resp in respuestas:
            with self.subTest(respuesta=resp):
                with patch("builtins.input", return_value=resp):
                    self.assertFalse(mod.preguntar_si_no("¿Pregunta?"))

    @patch("builtins.input", side_effect=["quizás", "123", "", "s"])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_preguntar_si_no_repite_si_invalido(self, mock_stdout, mock_input) -> None:
        resultado = mod.preguntar_si_no("¿Funciona?")
        self.assertTrue(resultado)
        self.assertEqual(mock_input.call_count, 4)
        salida = mock_stdout.getvalue()
        self.assertEqual(salida.count("Responde s o n.\n"), 3)


class TestRecogerDatosYEncadenamiento(unittest.TestCase):
    """Pruebas para recoger_datos() y su encadenamiento con evaluar_gate y render_markdown."""

    @patch("sys.stdout", new_callable=io.StringIO)
    @patch(
        "builtins.input",
        side_effect=[
            "",  # Alias vacío (repetirá)
            "Tester 156",  # Alias válido
            "Linux x86_64",  # Plataforma
            "abc1234",  # Build SHA
            "DualSense",  # Mando
            # 11 preguntas si/no con reintentos
            "invalido",  # Respuesta fuera de rango en la 1ª pregunta
            "s",  # oferta_comprensible = True
            "s",  # puntos_fisicos_claros = True
            "n",  # recorrido_completo = False
            "s",  # progreso_visible = True
            "s",  # abandono_seguro = True
            "s",  # jornada_continua = True
            "s",  # rehidratacion_correcta = True
            "s",  # opt_out_funciona = True
            "s",  # mando_fisico = True
            "s",  # foco_mando = True
            "s",  # sin_incidencia_bloqueante = True
            "Falló al interactuar con el punto 3",  # incidencia
            "Probar de nuevo en la siguiente build",  # observaciones
        ],
    )
    def test_recoger_datos_retorna_diccionario_esperado(
        self, mock_input, mock_stdout
    ) -> None:
        datos = mod.recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["participante"], "Tester 156")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "abc1234")
        self.assertEqual(datos["mando_modelo"], "DualSense")
        self.assertTrue(datos["oferta_comprensible"])
        self.assertTrue(datos["puntos_fisicos_claros"])
        self.assertFalse(datos["recorrido_completo"])
        self.assertTrue(datos["sin_incidencia_bloqueante"])
        self.assertEqual(
            datos["incidencia"], "Falló al interactuar con el punto 3"
        )
        self.assertEqual(
            datos["observaciones"], "Probar de nuevo en la siguiente build"
        )

    @patch("sys.stdout", new_callable=io.StringIO)
    @patch(
        "builtins.input",
        side_effect=[
            "Tester Completo",
            "Windows 11",  # Plataforma
            "789xyz",  # Build SHA
            "Xbox Controller",  # Mando
            # 11 CHECKS todos afirmativos
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "",  # incidencia opcional vacía
            "",  # observaciones opcionales vacías
        ],
    )
    def test_encadenar_recoger_datos_evaluar_gate_render_markdown(
        self, mock_input, mock_stdout
    ) -> None:
        datos = mod.recoger_datos()

        # Gate evaluación
        gate = mod.evaluar_gate(datos)
        self.assertTrue(gate["listo_para_valorar_cierre"])
        for check in mod.CHECKS:
            self.assertTrue(gate[check])

        # Render markdown
        markdown = mod.render_markdown(datos)
        self.assertIn("participante: Tester Completo", markdown)
        self.assertIn("plataforma: Windows 11", markdown)
        self.assertIn("build SHA: `789xyz`", markdown)
        self.assertIn("mando: Xbox Controller", markdown)
        self.assertIn("listo para valorar cierre de #156: **SÍ**", markdown)
        self.assertIn("Ninguna anotada.", markdown)
        self.assertIn("Sin observaciones adicionales.", markdown)


if __name__ == "__main__":
    unittest.main()
