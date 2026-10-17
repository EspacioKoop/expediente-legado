#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de preguntas e ingesta de datos en registrar_playtest_395.py."""

from datetime import datetime, timezone
import unittest
from unittest.mock import patch

from scripts.registrar_playtest_395 import (
    evaluar_gate,
    preguntar,
    preguntar_opcion,
    preguntar_si_no,
    recoger_datos,
    render_markdown,
)


class TestRegistrarPlaytest395Preguntas(unittest.TestCase):
    """Pruebas de comportamiento observable para preguntar, preguntar_si_no, preguntar_opcion y recoger_datos."""

    def test_preguntar_respuesta_valida_inmediata(self) -> None:
        """Verifica que preguntar devuelve la respuesta limpia cuando la primera entrada es válida."""
        with patch("builtins.input", return_value="  participante_395  "):
            resultado = preguntar("Alias: ")
        self.assertEqual(resultado, "participante_395")

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

    def test_preguntar_opcion_respuesta_valida_directa(self) -> None:
        """Verifica que preguntar_opcion acepta una opción válida directamente, sin importar mayúsculas o espacios."""
        opciones = ("bien", "rapida", "larga", "confusa")
        casos_validos = [
            ("bien", "bien"),
            ("  RAPIDA  ", "rapida"),
            ("Larga", "larga"),
            ("confusa", "confusa"),
        ]
        for entrada, esperada in casos_validos:
            with self.subTest(entrada=entrada):
                with patch("builtins.input", return_value=entrada):
                    resultado = preguntar_opcion("Ritmo", opciones)
                self.assertEqual(resultado, esperada)

    def test_preguntar_opcion_repite_ante_entradas_invalidas(self) -> None:
        """Verifica que preguntar_opcion repite cuando recibe respuestas fuera del conjunto de opciones."""
        opciones = ("bien", "desfasada", "confusa")
        respuestas = ["malo", "", "excelente", "  DESFASADA  "]
        with patch("builtins.input", side_effect=respuestas):
            resultado = preguntar_opcion("Sincronía", opciones)
        self.assertEqual(resultado, "desfasada")

    def test_recoger_datos_secuencia_completa(self) -> None:
        """Verifica que recoger_datos consume entradas interactivas (incluidas repeticiones) y construye el diccionario."""
        secuencia_input = [
            # Alias del participante (preguntar)
            "",
            "  Tester395  ",
            # Plataforma (preguntar)
            "Linux x86_64",
            # Build SHA (preguntar)
            "fedcba654321",
            # Conocimiento previo (preguntar_si_no)
            "invalido",
            "n",
            # entrada_lugar_respuesta (preguntar)
            "Una oficina noventera",
            # entrada_rol_respuesta (preguntar)
            "Un archivero administrativo",
            # entrada_tarea_respuesta (preguntar)
            "Clasificar documentos e ir al archivo",
            # entrada_ritmo (preguntar_opcion: bien/rapida/larga/confusa)
            "invalido",
            "bien",
            # entrada_lugar_correcto (preguntar_si_no)
            "s",
            # entrada_rol_correcto (preguntar_si_no)
            "si",
            # entrada_tarea_correcta (preguntar_si_no)
            "sí",
            # trayecto_continuidad_respuesta (preguntar)
            "Del archivo a la calle / salida de la oficina",
            # trayecto_ritmo (preguntar_opcion)
            "rapida",
            # trayecto_sincronia (preguntar_opcion: bien/desfasada/confusa)
            "bien",
            # trayecto_continuidad_correcta (preguntar_si_no)
            "s",
            # sueno_causa_respuesta (preguntar)
            "Acostarse en la cama para dormir",
            # sueno_ritmo (preguntar_opcion)
            "bien",
            # sueno_causa_correcta (preguntar_si_no)
            "s",
            # problema_reproducible (preguntar_si_no)
            "n",
            # incidencia (input libre opcional)
            "Ninguna",
            # observaciones (input libre opcional)
            "  Transición suave y fluida.  ",
        ]

        with patch("builtins.input", side_effect=secuencia_input):
            datos = recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["participante"], "Tester395")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "fedcba654321")
        self.assertFalse(datos["conocimiento_previo"])
        self.assertEqual(datos["entrada_lugar_respuesta"], "Una oficina noventera")
        self.assertEqual(datos["entrada_rol_respuesta"], "Un archivero administrativo")
        self.assertEqual(datos["entrada_tarea_respuesta"], "Clasificar documentos e ir al archivo")
        self.assertEqual(datos["entrada_ritmo"], "bien")
        self.assertTrue(datos["entrada_lugar_correcto"])
        self.assertTrue(datos["entrada_rol_correcto"])
        self.assertTrue(datos["entrada_tarea_correcta"])
        self.assertEqual(
            datos["trayecto_continuidad_respuesta"],
            "Del archivo a la calle / salida de la oficina",
        )
        self.assertEqual(datos["trayecto_ritmo"], "rapida")
        self.assertEqual(datos["trayecto_sincronia"], "bien")
        self.assertTrue(datos["trayecto_continuidad_correcta"])
        self.assertEqual(datos["sueno_causa_respuesta"], "Acostarse en la cama para dormir")
        self.assertEqual(datos["sueno_ritmo"], "bien")
        self.assertTrue(datos["sueno_causa_correcta"])
        self.assertFalse(datos["problema_reproducible"])
        self.assertEqual(datos["incidencia"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Transición suave y fluida.")

    def test_cadena_recoger_evaluar_render(self) -> None:
        """Verifica que los datos obtenidos por recoger_datos se consumen correctamente en evaluar_gate y render_markdown."""
        secuencia_input = [
            "User395",  # participante
            "Windows 11",  # plataforma
            "sha_build_395",  # build_sha
            "n",  # conocimiento_previo (False)
            "Oficina",  # entrada_lugar_respuesta
            "Empleado",  # entrada_rol_respuesta
            "Archivar",  # entrada_tarea_respuesta
            "bien",  # entrada_ritmo
            "s",  # entrada_lugar_correcto (True)
            "s",  # entrada_rol_correcto (True)
            "s",  # entrada_tarea_correcta (True)
            "Oficina a trayecto",  # trayecto_continuidad_respuesta
            "bien",  # trayecto_ritmo
            "bien",  # trayecto_sincronia
            "s",  # trayecto_continuidad_correcta (True)
            "Ir a dormir",  # sueno_causa_respuesta
            "bien",  # sueno_ritmo
            "s",  # sueno_causa_correcta (True)
            "n",  # problema_reproducible (False)
            "",  # incidencia
            "Sin observaciones",  # observaciones
        ]

        with patch("builtins.input", side_effect=secuencia_input):
            datos = recoger_datos()

        gate = evaluar_gate(datos)
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["comprension_entrada"])
        self.assertTrue(gate["comprension_trayecto"])
        self.assertTrue(gate["comprension_sueno"])
        self.assertTrue(gate["ritmo_sin_bloqueo"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

        markdown = render_markdown(datos)
        self.assertIn("# Registro de playtest humano · #395", markdown)
        self.assertIn("User395", markdown)
        self.assertIn("Windows 11", markdown)
        self.assertIn("`sha_build_395`", markdown)
        self.assertIn("Oficina", markdown)
        self.assertIn("Ninguna anotada.", markdown)
        self.assertIn("Sin observaciones", markdown)
        self.assertIn("listo para valorar cierre de #395: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
