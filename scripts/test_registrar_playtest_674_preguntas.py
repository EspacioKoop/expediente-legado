#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de preguntas e ingesta de datos en registrar_playtest_674.py."""

from datetime import datetime, timezone
import unittest
from unittest.mock import patch

from scripts.registrar_playtest_674 import (
    evaluar_gate,
    preguntar,
    preguntar_si_no,
    recoger_datos,
    render_markdown,
)


class TestRegistrarPlaytest674Preguntas(unittest.TestCase):
    """Pruebas de comportamiento observable para preguntar, preguntar_si_no y recoger_datos."""

    def test_preguntar_respuesta_valida_inmediata(self) -> None:
        """Verifica que preguntar devuelve la respuesta limpia cuando la primera entrada es válida."""
        with patch("builtins.input", return_value="  tester_1  "):
            resultado = preguntar("Tester: ")
        self.assertEqual(resultado, "tester_1")

    def test_preguntar_repite_ante_entradas_vacias_o_espacios(self) -> None:
        """Verifica que preguntar ignora cadenas vacías o compuestas de espacios y repite hasta obtener valor."""
        respuestas = ["", "   ", "\t", "  tester_valido  "]
        with patch("builtins.input", side_effect=respuestas):
            resultado = preguntar("Tester: ")
        self.assertEqual(resultado, "tester_valido")

    def test_preguntar_si_no_respuestas_afirmativas(self) -> None:
        """Verifica que preguntar_si_no reconoce s, si y sí en distintas variantes de mayúsculas/espacios."""
        casos_afirmativos = ["s", "S", "  si  ", "SI", "sí", "SÍ", "  Sí  "]
        for entrada in casos_afirmativos:
            with self.subTest(entrada=entrada):
                with patch("builtins.input", return_value=entrada):
                    resultado = preguntar_si_no("¿Pregunta?")
                self.assertTrue(resultado)

    def test_preguntar_si_no_respuestas_negativas(self) -> None:
        """Verifica que preguntar_si_no reconoce n y no en distintas variantes de mayúsculas/espacios."""
        casos_negativos = ["n", "N", "  no  ", "NO", "No"]
        for entrada in casos_negativos:
            with self.subTest(entrada=entrada):
                with patch("builtins.input", return_value=entrada):
                    resultado = preguntar_si_no("¿Pregunta?")
                self.assertFalse(resultado)

    def test_preguntar_si_no_repite_ante_entradas_invalidas(self) -> None:
        """Verifica que preguntar_si_no repite la pregunta cuando recibe respuestas fuera de rango o vacías."""
        respuestas = ["quizás", "", "123", "tal vez", "  s  "]
        with patch("builtins.input", side_effect=respuestas):
            resultado = preguntar_si_no("¿Pregunta?")
        self.assertTrue(resultado)

    def test_recoger_datos_secuencia_completa(self) -> None:
        """Verifica que recoger_datos consume entradas interactivas (incluidas repeticiones) y construye el diccionario."""
        secuencia_input = [
            # Tester (preguntar) - con repetición por vacío
            "",
            "  Tester674  ",
            # Plataforma (preguntar)
            "Linux x86_64",
            # Build SHA (preguntar)
            "abc123def456",
            # Viewport (preguntar)
            "1920x1080",
            # Teclado real (preguntar_si_no) - con repetición por invalidez
            "invalido",
            "s",
            # Mando físico (preguntar_si_no)
            "si",
            # Modelo de mando (preguntar)
            "Xbox Controller",
            # Ignorar no bloquea (preguntar_si_no)
            "sí",
            # --- Escenario: quiosco ---
            "s",  # portada_legible
            "s",  # compra_clara
            "s",  # foco_ok
            "https://evidencia.test/quiosco.png",  # captura
            "Comprado con éxito",  # notas
            # --- Escenario: hallazgo ---
            "s",  # escala_creible
            "s",  # identidad_legible
            "s",  # recogida_clara
            "https://evidencia.test/hallazgo.png",  # captura
            "",  # notas (opcional)
            # --- Escenario: casa ---
            "s",  # materializacion_clara
            "s",  # sin_solapes
            "s",  # lectura_desde_casa
            "https://evidencia.test/casa.png",  # captura
            "Colocado en estantería",  # notas
            # --- Escenario: visor ---
            "s",  # cuatro_piezas
            "s",  # texto_legible
            "s",  # escala_texto
            "s",  # teclado_ok
            "s",  # mando_ok
            "https://evidencia.test/visor.png",  # captura
            "",  # notas
            # Cierre
            "Ninguna",  # incidencias
            "Todo excelente",  # observaciones
        ]

        with patch("builtins.input", side_effect=secuencia_input):
            datos = recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["tester"], "Tester674")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "abc123def456")
        self.assertEqual(datos["viewport"], "1920x1080")
        self.assertTrue(datos["teclado_real"])
        self.assertTrue(datos["mando_fisico"])
        self.assertEqual(datos["mando_modelo"], "Xbox Controller")
        self.assertTrue(datos["ignorar_no_bloquea"])

        escenarios = datos["escenarios"]
        self.assertIsInstance(escenarios, dict)
        self.assertIn("quiosco", escenarios)
        self.assertIn("hallazgo", escenarios)
        self.assertIn("casa", escenarios)
        self.assertIn("visor", escenarios)

        quiosco = escenarios["quiosco"]
        self.assertTrue(quiosco["portada_legible"])
        self.assertTrue(quiosco["compra_clara"])
        self.assertTrue(quiosco["foco_ok"])
        self.assertEqual(quiosco["captura"], "https://evidencia.test/quiosco.png")
        self.assertEqual(quiosco["notas"], "Comprado con éxito")

        self.assertEqual(datos["incidencias"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Todo excelente")

    def test_cadena_recoger_evaluar_render(self) -> None:
        """Verifica que los datos obtenidos por recoger_datos se consumen correctamente en evaluar_gate y render_markdown."""
        secuencia_input = [
            "Facilitador674",  # tester
            "Windows 11",  # plataforma
            "sha_build_674",  # build_sha
            "1920x1080",  # viewport
            "s",  # teclado_real
            "s",  # mando_fisico
            "DualSense",  # mando_modelo
            "s",  # ignorar_no_bloquea
            # quiosco
            "s",
            "s",
            "s",
            "evidencia_quiosco.png",
            "ok",
            # hallazgo
            "s",
            "s",
            "s",
            "evidencia_hallazgo.png",
            "ok",
            # casa
            "s",
            "s",
            "s",
            "evidencia_casa.png",
            "ok",
            # visor
            "s",
            "s",
            "s",
            "s",
            "s",
            "evidencia_visor.png",
            "ok",
            # Cierre
            "Sin incidencias",
            "Observaciones del test",
        ]

        with patch("builtins.input", side_effect=secuencia_input):
            datos = recoger_datos()

        gate = evaluar_gate(datos)
        self.assertTrue(gate["viewport_ok"])
        self.assertTrue(gate["dispositivos_ok"])
        self.assertTrue(gate["escenarios_ok"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["opcionalidad_ok"])
        self.assertTrue(gate["listo_para_cerrar"])

        markdown = render_markdown(datos)
        self.assertIn("# Registro de playtest de publicaciones · #674", markdown)
        self.assertIn("Facilitador674", markdown)
        self.assertIn("Windows 11", markdown)
        self.assertIn("`sha_build_674`", markdown)
        self.assertIn("`1920x1080`", markdown)
        self.assertIn("DualSense", markdown)
        self.assertIn("Sin incidencias", markdown)
        self.assertIn("Observaciones del test", markdown)
        self.assertIn("listo para valorar cierre de #674: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
