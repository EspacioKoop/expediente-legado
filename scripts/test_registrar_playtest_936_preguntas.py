#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de preguntas e ingesta de datos en registrar_playtest_936.py."""

from datetime import datetime, timezone
import unittest
from unittest.mock import patch

from scripts.registrar_playtest_936 import (
    evaluar_registro,
    preguntar,
    preguntar_si_no,
    recoger_datos,
    render_markdown,
)


class TestRegistrarPlaytest936Preguntas(unittest.TestCase):
    """Pruebas de comportamiento observable para preguntar, preguntar_si_no y recoger_datos."""

    def test_preguntar_respuesta_valida_inmediata(self) -> None:
        """Verifica que preguntar devuelve la respuesta limpia cuando la primera entrada es válida."""
        with patch("builtins.input", return_value="  tester_1  "):
            resultado = preguntar("Tester/facilitador: ")
        self.assertEqual(resultado, "tester_1")

    def test_preguntar_repite_ante_entradas_vacias_o_espacios(self) -> None:
        """Verifica que preguntar ignora cadenas vacías o compuestas de espacios y repite hasta obtener valor."""
        respuestas = ["", "   ", "\t", "  tester_valido  "]
        with patch("builtins.input", side_effect=respuestas):
            resultado = preguntar("Tester/facilitador: ")
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
        """Verifica que recoger_datos consume entradas interactivas (incluidas repeticiones) y construye el diccionario de datos."""
        secuencia_input = [
            # Tester (preguntar con reintento)
            "",
            "  Alice  ",
            # Plataforma (preguntar)
            "Linux x86_64",
            # Build SHA (preguntar)
            "abc1234def56",
            # Escenario base
            # hud_legible (preguntar_si_no con reintento)
            "invalido",
            "s",
            # combate_completo (preguntar_si_no)
            "s",
            # evidencia (preguntar)
            "https://evidencia.org/base.png",
            # observaciones (input libre opcional)
            "Observación base",
            # Escenario no_iniciar
            # hud_legible (preguntar_si_no)
            "s",
            # combate_completo (preguntar_si_no)
            "s",
            # claridad (preguntar_si_no)
            "s",
            # coste (preguntar_si_no)
            "s",
            # cambio_decision (preguntar_si_no)
            "s",
            # utilidad_contextual (preguntar_si_no)
            "s",
            # evidencia (preguntar)
            "https://evidencia.org/no_iniciar.png",
            # observaciones (input libre opcional)
            "Observación no_iniciar",
            # Escenario tregua
            # hud_legible (preguntar_si_no)
            "s",
            # combate_completo (preguntar_si_no)
            "s",
            # claridad (preguntar_si_no)
            "s",
            # coste (preguntar_si_no)
            "s",
            # cambio_decision (preguntar_si_no)
            "s",
            # utilidad_contextual (preguntar_si_no)
            "s",
            # evidencia (preguntar)
            "https://evidencia.org/tregua.png",
            # observaciones (input libre opcional)
            "Observación tregua",
            # Cierre transversal
            # matriz_teclado_completa (preguntar_si_no)
            "s",
            # reduccion_movimiento_equivalente (preguntar_si_no)
            "s",
            # muestra_mando_fisico (preguntar_si_no)
            "n",
            # observaciones_generales (input libre opcional)
            "  Sesión sin problemas.  ",
        ]

        fecha_fija = datetime(2026, 10, 17, 12, 0, 0, tzinfo=timezone.utc)

        class MockDatetime:
            @classmethod
            def now(cls) -> datetime:
                return fecha_fija

        with patch("builtins.input", side_effect=secuencia_input), patch(
            "scripts.registrar_playtest_936.datetime", MockDatetime
        ):
            datos = recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["tester"], "Alice")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "abc1234def56")
        self.assertTrue(isinstance(datos["escenarios"], dict))
        self.assertEqual(set(datos["escenarios"].keys()), {"base", "no_iniciar", "tregua"})
        self.assertTrue(datos["matriz_teclado_completa"])
        self.assertTrue(datos["reduccion_movimiento_equivalente"])
        self.assertFalse(datos["muestra_mando_fisico"])
        self.assertEqual(datos["observaciones_generales"], "Sesión sin problemas.")

    def test_cadena_recoger_evaluar_render(self) -> None:
        """Verifica que los datos obtenidos por recoger_datos se consumen correctamente en evaluar_registro y render_markdown."""
        secuencia_input = [
            "Bob",  # tester
            "Windows 11",  # plataforma
            "fedcba654321",  # build_sha
            # Escenario base
            "s",  # hud_legible
            "s",  # combate_completo
            "https://evidencia.org/base.png",  # evidencia
            "",  # observaciones
            # Escenario no_iniciar
            "s",  # hud_legible
            "s",  # combate_completo
            "s",  # claridad
            "s",  # coste
            "s",  # cambio_decision
            "s",  # utilidad_contextual
            "https://evidencia.org/no_iniciar.png",  # evidencia
            "",  # observaciones
            # Escenario tregua
            "s",  # hud_legible
            "s",  # combate_completo
            "s",  # claridad
            "s",  # coste
            "s",  # cambio_decision
            "s",  # utilidad_contextual
            "https://evidencia.org/tregua.png",  # evidencia
            "",  # observaciones
            # Cierre transversal
            "s",  # matriz_teclado_completa
            "s",  # reduccion_movimiento_equivalente
            "s",  # muestra_mando_fisico
            "Observaciones globales de prueba",  # observaciones_generales
        ]

        with patch("builtins.input", side_effect=secuencia_input):
            datos = recoger_datos()

        gate = evaluar_registro(datos)
        self.assertTrue(gate["matriz_completa"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["comunes_ok"])
        self.assertTrue(gate["compromisos_ok"])
        self.assertTrue(gate["teclado_ok"])
        self.assertTrue(gate["reduccion_ok"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

        markdown = render_markdown(datos)
        self.assertIn("# Registro de playtest · religión y conflicto #936", markdown)
        self.assertIn("tester/facilitador: Bob", markdown)
        self.assertIn("plataforma: Windows 11", markdown)
        self.assertIn("build SHA: `fedcba654321`", markdown)
        self.assertIn("Compromiso · no iniciar agresión", markdown)
        self.assertIn("Observaciones globales de prueba", markdown)
        self.assertIn("listo para valorar cierre de #936:", markdown)
        self.assertIn("**SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
