#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de preguntas y recolección de datos de registrar_playtest_957.py."""

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

import registrar_playtest_957 as mod


class TestPreguntar(unittest.TestCase):
    """Pruebas para preguntar(prompt)."""

    @patch("builtins.input", side_effect=["  Tester Beta  "])
    def test_preguntar_respuesta_valida_directa(self, mock_input) -> None:
        resultado = mod.preguntar("Tester: ")
        self.assertEqual(resultado, "Tester Beta")
        mock_input.assert_called_once_with("Tester: ")

    @patch("builtins.input", side_effect=["", "   ", "\t", "  Facilitador 1  "])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_preguntar_repite_si_vacio(self, mock_stdout, mock_input) -> None:
        resultado = mod.preguntar("Tester: ")
        self.assertEqual(resultado, "Facilitador 1")
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

    @patch("builtins.input", side_effect=["tal vez", "123", "", "s"])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_preguntar_si_no_repite_si_invalido(self, mock_stdout, mock_input) -> None:
        resultado = mod.preguntar_si_no("¿Funciona?")
        self.assertTrue(resultado)
        self.assertEqual(mock_input.call_count, 4)
        salida = mock_stdout.getvalue()
        self.assertEqual(salida.count("Responde s o n.\n"), 3)


class TestPreguntarEntero(unittest.TestCase):
    """Pruebas para preguntar_entero(prompt, minimo)."""

    @patch("builtins.input", side_effect=["5"])
    def test_preguntar_entero_valido_directo(self, mock_input) -> None:
        resultado = mod.preguntar_entero("Número de zonas: ", minimo=0)
        self.assertEqual(resultado, 5)
        mock_input.assert_called_once_with("Número de zonas: ")

    @patch("builtins.input", side_effect=["abc", "-2", "0", "3"])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_preguntar_entero_repite_si_invalido_o_menor_que_minimo(
        self, mock_stdout, mock_input
    ) -> None:
        resultado = mod.preguntar_entero("Mínimo 1: ", minimo=1)
        self.assertEqual(resultado, 3)
        self.assertEqual(mock_input.call_count, 4)
        salida = mock_stdout.getvalue()
        self.assertIn("Introduce un número entero.\n", salida)
        self.assertIn("El valor mínimo es 1.\n", salida)


class TestRecogerDatosYEncadenamiento(unittest.TestCase):
    """Pruebas para recoger_datos() y su encadenamiento con evaluar_gate y render_markdown."""

    @patch("sys.stdout", new_callable=io.StringIO)
    @patch(
        "builtins.input",
        side_effect=[
            "",  # Tester vacío (repetirá)
            "Tester 957",  # Tester válido
            "Linux x86_64",  # Plataforma
            "def4567",  # Build SHA
            "abc",  # Zonas probadas no entero
            "-1",  # Zonas probadas < 0
            "3",  # Zonas probadas válidas = 3
            "Zona A, Zona B, Zona C",  # Zonas/recorrido
            # 14 preguntas si/no para los CRITERIOS con reintento en la 1ª
            "quizas",  # Respuesta fuera de rango
            "s",  # dos_zonas
            "s",  # suelo_y_pared
            "s",  # tipos_por_forma
            "s",  # texto_local
            "s",  # densidad_legible
            "s",  # limite_correcto
            "s",  # borrado_correcto
            "s",  # limpieza_aislada
            "s",  # persistencia_real
            "s",  # sin_colisiones
            "s",  # opcional
            "s",  # estres_legible
            "s",  # sin_tapar_critico
            "s",  # estetica_coherente
            "https://evidencia.local/logs.txt",  # evidencia
            "Ninguna incidencia detectada",  # incidencias
        ],
    )
    def test_recoger_datos_retorna_diccionario_esperado(
        self, mock_input, mock_stdout
    ) -> None:
        datos = mod.recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["tester"], "Tester 957")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "def4567")
        self.assertEqual(datos["zonas_probadas"], 3)
        self.assertEqual(datos["zonas"], "Zona A, Zona B, Zona C")
        self.assertIsInstance(datos["criterios"], dict)
        criterios = datos["criterios"]
        self.assertEqual(len(criterios), 14)
        for clave, _desc in mod.CRITERIOS:
            self.assertTrue(criterios[clave])
        self.assertEqual(datos["evidencia"], "https://evidencia.local/logs.txt")
        self.assertEqual(datos["incidencias"], "Ninguna incidencia detectada")

    @patch("sys.stdout", new_callable=io.StringIO)
    @patch(
        "builtins.input",
        side_effect=[
            "Tester Completo",
            "Windows 11",  # Plataforma
            "957sha",  # Build SHA
            "2",  # Zonas probadas
            "Zona 1 y Zona 2",  # Zonas
            # 14 Criterios afirmativos
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
            "s",
            "s",
            "s",
            "logs y capturas anexas",  # evidencia
            "",  # incidencias opcionales vacías
        ],
    )
    def test_encadenar_recoger_datos_evaluar_gate_render_markdown(
        self, mock_input, mock_stdout
    ) -> None:
        datos = mod.recoger_datos()

        # Gate evaluación
        gate = mod.evaluar_gate(datos)
        self.assertTrue(gate["listo_para_valorar_cierre"])
        for clave, _desc in mod.CRITERIOS:
            self.assertTrue(gate[clave])
        self.assertTrue(gate["zonas_identificadas"])
        self.assertTrue(gate["evidencia_trazable"])

        # Render markdown
        markdown = mod.render_markdown(datos)
        self.assertIn("tester/facilitador: Tester Completo", markdown)
        self.assertIn("plataforma: Windows 11", markdown)
        self.assertIn("build SHA: `957sha`", markdown)
        self.assertIn("zonas probadas: 2", markdown)
        self.assertIn("zonas/recorrido: Zona 1 y Zona 2", markdown)
        self.assertIn("listo para valorar cierre de #957: **SÍ**", markdown)
        self.assertIn("logs y capturas anexas", markdown)
        self.assertIn("Ninguna anotada.", markdown)


if __name__ == "__main__":
    unittest.main()
