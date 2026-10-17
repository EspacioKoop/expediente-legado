#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de preguntas e ingesta de datos en registrar_playtest_126.py."""

from datetime import datetime, timezone
import unittest
from unittest.mock import patch

from scripts.registrar_playtest_126 import (
    evaluar_gate,
    preguntar,
    preguntar_si_no,
    recoger_datos,
    render_markdown,
)


class TestRegistrarPlaytest126Preguntas(unittest.TestCase):
    """Pruebas de comportamiento observable para preguntar, preguntar_si_no y recoger_datos."""

    def test_preguntar_respuesta_valida_inmediata(self) -> None:
        """Verifica que preguntar devuelve la respuesta limpia cuando la primera entrada es válida."""
        with patch("builtins.input", return_value="  participante_1  "):
            resultado = preguntar("Alias: ")
        self.assertEqual(resultado, "participante_1")

    def test_preguntar_repite_ante_entradas_vacias_o_espacios(self) -> None:
        """Verifica que preguntar ignora cadenas vacías o compuestas de espacios y repite hasta obtener valor."""
        respuestas = ["", "   ", "\t", "  alias_valido  "]
        with patch("builtins.input", side_effect=respuestas):
            resultado = preguntar("Alias: ")
        self.assertEqual(resultado, "alias_valido")

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
        """Verifica que recoger_datos consume entradas interactivas (incluidas repeticiones por entradas vacías) y construye el diccionario de datos."""
        # Secuencia con entradas inválidas intermediate para ejercitar la repetición
        secuencia_input = [
            # Alias del participante (preguntar)
            "",
            "  TesterAlpha  ",
            # Plataforma (preguntar)
            "Linux x86_64",
            # Build SHA (preguntar)
            "a1b2c3d4e5f6",
            # Gate visual SHA (preguntar)
            "a1b2c3d4e5f6",
            # Conocimiento previo (preguntar_si_no)
            "invalido",
            "n",
            # respuesta_lugar (preguntar)
            "Oficina administrativa con archivo",
            # respuesta_zonas (preguntar)
            "Puestos de trabajo, estanterías de archivo y cafetera",
            # respuesta_recorrido (preguntar)
            "No, la circulación era fluida y las salidas claras",
            # respuesta_tecnica (preguntar)
            "No, parecía un espacio funcional",
            # lugar_reconocido (preguntar_si_no)
            "s",
            # zonas_reconocidas (preguntar_si_no)
            "si",
            # salida_encontrada (preguntar_si_no)
            "sí",
            # recorrido_claro (preguntar_si_no)
            "s",
            # problema_sala_tecnica (preguntar_si_no)
            "n",
            # incidencia_reproducible (preguntar_si_no)
            "no",
            # incidencia (input libre opcional)
            "",
            # observaciones (input libre opcional)
            "  Sesión sin contratiempos.  ",
        ]

        fecha_fija = datetime(2026, 10, 17, 12, 0, 0, tzinfo=timezone.utc)

        class MockDatetime:
            @classmethod
            def now(cls) -> datetime:
                return fecha_fija

        with patch("builtins.input", side_effect=secuencia_input), patch(
            "scripts.registrar_playtest_126.datetime", MockDatetime
        ):
            datos = recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["participante"], "TesterAlpha")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "a1b2c3d4e5f6")
        self.assertEqual(datos["gate_visual_sha"], "a1b2c3d4e5f6")
        self.assertFalse(datos["conocimiento_previo"])
        self.assertEqual(datos["respuesta_lugar"], "Oficina administrativa con archivo")
        self.assertTrue(datos["lugar_reconocido"])
        self.assertTrue(datos["zonas_reconocidas"])
        self.assertTrue(datos["salida_encontrada"])
        self.assertTrue(datos["recorrido_claro"])
        self.assertFalse(datos["problema_sala_tecnica"])
        self.assertFalse(datos["incidencia_reproducible"])
        self.assertEqual(datos["incidencia"], "")
        self.assertEqual(datos["observaciones"], "Sesión sin contratiempos.")

    def test_cadena_recoger_evaluar_render(self) -> None:
        """Verifica que los datos obtenidos por recoger_datos se consumen correctamente en evaluar_gate y render_markdown."""
        secuencia_input = [
            "User126",  # participante
            "Windows 11",  # plataforma
            "sha_build_999",  # build_sha
            "sha_build_999",  # gate_visual_sha
            "n",  # conocimiento_previo (False)
            "Oficina de registro",  # respuesta_lugar
            "Mesas y cajas",  # respuesta_zonas
            "Ninguno",  # respuesta_recorrido
            "No",  # respuesta_tecnica
            "s",  # lugar_reconocido (True)
            "s",  # zonas_reconocidas (True)
            "s",  # salida_encontrada (True)
            "s",  # recorrido_claro (True)
            "n",  # problema_sala_tecnica (False)
            "n",  # incidencia_reproducible (False)
            "Sin incidencias",  # incidencia
            "Todo en orden",  # observaciones
        ]

        with patch("builtins.input", side_effect=secuencia_input):
            datos = recoger_datos()

        gate = evaluar_gate(datos)
        self.assertTrue(gate["evidencia_misma_build"])
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["lugar_reconocido"])
        self.assertTrue(gate["zonas_reconocidas"])
        self.assertTrue(gate["salida_encontrada"])
        self.assertTrue(gate["recorrido_claro"])
        self.assertTrue(gate["sin_lectura_tecnica"])
        self.assertTrue(gate["sin_incidencia"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

        markdown = render_markdown(datos)
        self.assertIn("# Registro de playtest humano · #126", markdown)
        self.assertIn("User126", markdown)
        self.assertIn("Windows 11", markdown)
        self.assertIn("`sha_build_999`", markdown)
        self.assertIn("Oficina de registro", markdown)
        self.assertIn("Sin incidencias", markdown)
        self.assertIn("Todo en orden", markdown)
        self.assertIn("listo para valorar cierre de #126: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
