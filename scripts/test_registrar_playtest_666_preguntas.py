#!/usr/bin/env python3
"""Pruebas unitarias para preguntar, preguntar_si_no y recoger_datos en registrar_playtest_666.py."""

from datetime import datetime, timezone
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

import registrar_playtest_666 as mod


class TestPreguntar(unittest.TestCase):
    """Pruebas de comportamiento observable para la función preguntar."""

    @patch("builtins.input", side_effect=["  Tester Alpha  "])
    def test_preguntar_respuesta_valida_directa(self, mock_input) -> None:
        """Verifica que preguntar devuelve la cadena limpia cuando la primera respuesta es válida."""
        resultado = mod.preguntar("Tester: ")
        self.assertEqual(resultado, "Tester Alpha")
        mock_input.assert_called_once_with("Tester: ")

    @patch("builtins.input", side_effect=["", "   ", "\t", "  Facilitador 1  "])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_preguntar_repite_ante_entradas_vacias_o_espacios(
        self, mock_stdout, mock_input
    ) -> None:
        """Verifica que preguntar ignora entradas vacías/espacios y repite hasta obtener una respuesta válida."""
        resultado = mod.preguntar("Tester: ")
        self.assertEqual(resultado, "Facilitador 1")
        self.assertEqual(mock_input.call_count, 4)
        salida = mock_stdout.getvalue()
        self.assertEqual(
            salida.count("La respuesta no puede quedar vacía.\n"), 3
        )


class TestPreguntarSiNo(unittest.TestCase):
    """Pruebas de comportamiento observable para la función preguntar_si_no."""

    def test_preguntar_si_no_respuestas_afirmativas(self) -> None:
        """Verifica que preguntar_si_no reconoce variaciones afirmativas (s, si, sí, mayúsculas, espacios)."""
        casos = ["s", "S", "si", "SI", "sí", "SÍ", "  s  ", "  Si  "]
        for respuesta in casos:
            with self.subTest(respuesta=respuesta):
                with patch("builtins.input", return_value=respuesta):
                    self.assertTrue(mod.preguntar_si_no("¿Pregunta?"))

    def test_preguntar_si_no_respuestas_negativas(self) -> None:
        """Verifica que preguntar_si_no reconoce variaciones negativas (n, no, mayúsculas, espacios)."""
        casos = ["n", "N", "no", "NO", "  n  ", "  No  "]
        for respuesta in casos:
            with self.subTest(respuesta=respuesta):
                with patch("builtins.input", return_value=respuesta):
                    self.assertFalse(mod.preguntar_si_no("¿Pregunta?"))

    @patch("builtins.input", side_effect=["quizás", "123", "", "s"])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_preguntar_si_no_repite_ante_entradas_invalidas(
        self, mock_stdout, mock_input
    ) -> None:
        """Verifica que preguntar_si_no solicita de nuevo la respuesta cuando recibe opciones fuera de rango."""
        resultado = mod.preguntar_si_no("¿Aprobado?")
        self.assertTrue(resultado)
        self.assertEqual(mock_input.call_count, 4)
        salida = mock_stdout.getvalue()
        self.assertEqual(salida.count("Responde s o n.\n"), 3)


class TestRecogerDatosYEncadenamiento(unittest.TestCase):
    """Pruebas para recoger_datos y su encadenamiento con evaluar_gate y render_markdown."""

    @patch("sys.stdout", new_callable=io.StringIO)
    def test_recoger_datos_secuencia_completa_con_reintentos(
        self, mock_stdout
    ) -> None:
        """Verifica que recoger_datos consume la secuencia completa de entradas (incluidos reintentos) y arma el diccionario."""
        secuencia_input = [
            # Datos generales (preguntar / preguntar_si_no)
            "",  # Tester vacío (repite)
            "Tester 666",  # Tester
            "Linux x86_64",  # Plataforma
            "abc1234def56789",  # Build SHA
            "1920x1080",  # Viewport
            "invalid_option",  # teclado_real fuera de rango (repite)
            "s",  # teclado_real = True
            "s",  # mando_fisico = True
            "DualSense OS98",  # mando_modelo
            "s",  # reduccion_movimiento_probada = True
            # Escenario 1: apertura (3 checks + evidencia + notas)
            "s",  # descubrible = True
            "s",  # presencia_legible = True
            "s",  # foco_inicial = True
            "https://evidencia.test/apertura.png",  # evidencia
            "Foco comprobado",  # notas
            # Escenario 2: navegacion (4 checks + evidencia + notas)
            "s",  # teclado_ok = True
            "s",  # mando_ok = True
            "s",  # cancelar_ok = True
            "s",  # escala_ok = True
            "https://evidencia.test/navegacion.mp4",  # evidencia
            "Navegación correcta",  # notas
            # Escenario 3: respuestas (4 checks + evidencia + notas)
            "s",  # sin_texto_libre = True
            "s",  # respuesta_clara = True
            "s",  # persiste = True
            "s",  # ignorar_no_bloquea = True
            "https://evidencia.test/respuestas.png",  # evidencia
            "Persistencia verificada",  # notas
            # Escenario 4: incidencia (4 checks + evidencia + notas)
            "s",  # evento_real = True
            "s",  # canal_aparece = True
            "s",  # mensajes_legibles = True
            "s",  # sin_progreso_paralelo = True
            "https://evidencia.test/incidencia.png",  # evidencia
            "Incidencia tratada",  # notas
            # Cierre libre
            "Ninguna incidencia grave",  # incidencias
            "Sesión completada sin fallos",  # observaciones
        ]

        fecha_fija = datetime(2026, 10, 17, 12, 0, 0, tzinfo=timezone.utc)

        class MockDatetime:
            @classmethod
            def now(cls) -> datetime:
                return fecha_fija

        with patch("builtins.input", side_effect=secuencia_input), patch(
            "registrar_playtest_666.datetime", MockDatetime
        ):
            datos = mod.recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["tester"], "Tester 666")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "abc1234def56789")
        self.assertEqual(datos["viewport"], "1920x1080")
        self.assertTrue(datos["teclado_real"])
        self.assertTrue(datos["mando_fisico"])
        self.assertEqual(datos["mando_modelo"], "DualSense OS98")
        self.assertTrue(datos["reduccion_movimiento_probada"])

        escenarios = datos["escenarios"]
        self.assertIsInstance(escenarios, dict)
        self.assertIn("apertura", escenarios)
        self.assertIn("navegacion", escenarios)
        self.assertIn("respuestas", escenarios)
        self.assertIn("incidencia", escenarios)

        self.assertTrue(escenarios["apertura"]["descubrible"])
        self.assertEqual(
            escenarios["apertura"]["evidencia"],
            "https://evidencia.test/apertura.png",
        )
        self.assertEqual(escenarios["apertura"]["notas"], "Foco comprobado")

        self.assertEqual(datos["incidencias"], "Ninguna incidencia grave")
        self.assertEqual(datos["observaciones"], "Sesión completada sin fallos")

    @patch("sys.stdout", new_callable=io.StringIO)
    def test_encadenamiento_recoger_evaluar_render(self, mock_stdout) -> None:
        """Verifica que el diccionario devuelto por recoger_datos alimenta evaluar_gate y render_markdown correctamente."""
        secuencia_input = [
            "Tester Integracion",  # tester
            "Linux x86_64",  # plataforma
            "sha_build_666",  # build_sha
            "1920x1080",  # viewport
            "s",  # teclado_real
            "s",  # mando_fisico
            "Xbox Controller",  # mando_modelo
            "s",  # reduccion_movimiento_probada
            # apertura
            "s",
            "s",
            "s",
            "evidencia_apertura.png",
            "ok",
            # navegacion
            "s",
            "s",
            "s",
            "s",
            "evidencia_navegacion.png",
            "ok",
            # respuestas
            "s",
            "s",
            "s",
            "s",
            "evidencia_respuestas.png",
            "ok",
            # incidencia
            "s",
            "s",
            "s",
            "s",
            "evidencia_incidencia.png",
            "ok",
            # cierre
            "Sin incidencias",
            "Todo en orden",
        ]

        with patch("builtins.input", side_effect=secuencia_input):
            datos = mod.recoger_datos()

        gate = mod.evaluar_gate(datos)
        self.assertTrue(gate["viewport_ok"])
        self.assertTrue(gate["dispositivos_ok"])
        self.assertTrue(gate["reduccion_ok"])
        self.assertTrue(gate["escenarios_ok"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["listo_para_cerrar"])

        markdown = mod.render_markdown(datos)
        self.assertIn("# Registro de playtest de Mensajería interna · #666", markdown)
        self.assertIn("Tester Integracion", markdown)
        self.assertIn("Linux x86_64", markdown)
        self.assertIn("`sha_build_666`", markdown)
        self.assertIn("`1920x1080`", markdown)
        self.assertIn("Sin incidencias", markdown)
        self.assertIn("Todo en orden", markdown)
        self.assertIn("listo para valorar cierre de #666: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
