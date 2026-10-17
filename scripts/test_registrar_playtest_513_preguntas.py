#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de preguntas e ingesta de datos en registrar_playtest_513.py."""

from datetime import datetime, timezone
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from registrar_playtest_513 import (  # noqa: E402
    FOLIOS,
    evaluar_gate,
    preguntar,
    preguntar_si_no,
    recoger_datos,
    render_markdown,
)


class TestRegistrarPlaytest513Preguntas(unittest.TestCase):
    """Pruebas de comportamiento observable para preguntar, preguntar_si_no y recoger_datos."""

    def test_preguntar_respuesta_valida_inmediata(self) -> None:
        """Verifica que preguntar devuelve la respuesta limpia cuando la primera entrada es válida."""
        with patch("builtins.input", return_value="  Facilitador 1  "):
            resultado = preguntar("Tester: ")
        self.assertEqual(resultado, "Facilitador 1")

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
        """Verifica que recoger_datos consume entradas interactivas (incluidas repeticiones por entradas vacías) y construye el diccionario de datos."""
        secuencia_input = [
            # Tester (preguntar, con reintento)
            "",
            "  TesterAlpha  ",
            # Plataforma (preguntar)
            "Linux x86_64",
            # Build SHA (preguntar)
            "a1b2c3d4e5f6",
            # 4 folios: F-1999-00231, MEMO-1999-088, EMP-0456, ACTA-1999-014
            # Folio 1: F-1999-00231 (cabecera, lectura, sin_recorte, desplazamiento, captura, notas)
            "invalid_s_n",
            "s",  # cabecera_visible
            "s",  # lectura_completa
            "s",  # sin_recorte
            "s",  # desplazamiento_ok
            "",
            "captura1.png",  # captura (preguntar)
            "Nota 1",  # notas (input)
            # Folio 2: MEMO-1999-088
            "s",
            "s",
            "s",
            "s",
            "captura2.png",
            "",  # notas vacías
            # Folio 3: EMP-0456
            "s",
            "s",
            "s",
            "s",
            "captura3.png",
            "Nota 3",
            # Folio 4: ACTA-1999-014
            "s",
            "s",
            "s",
            "s",
            "captura4.png",
            "Nota 4",
            # Comprobaciones cruzadas
            "s",  # gatillo_memo_ok
            "s",  # gatillo_ficha_ok
            "s",  # peritaje_no_conclusion
            "s",  # acta_no_conclusion
            "s",  # relectura_sin_coste
            "s",  # relaciones_no_automaticas
            # Incidencia (input)
            "Ninguna",
            # Observaciones (input)
            "  Sesión sin contratiempos.  ",
        ]

        fecha_fija = datetime(2026, 10, 17, 12, 0, 0, tzinfo=timezone.utc)

        class MockDatetime:
            @classmethod
            def now(cls) -> datetime:
                return fecha_fija

        with patch("builtins.input", side_effect=secuencia_input), patch(
            "registrar_playtest_513.datetime", MockDatetime
        ):
            datos = recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["tester"], "TesterAlpha")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "a1b2c3d4e5f6")
        self.assertIn("folios", datos)
        self.assertEqual(len(datos["folios"]), len(FOLIOS))
        self.assertTrue(datos["gatillo_memo_ok"])
        self.assertTrue(datos["gatillo_ficha_ok"])
        self.assertTrue(datos["peritaje_no_conclusion"])
        self.assertTrue(datos["acta_no_conclusion"])
        self.assertTrue(datos["relectura_sin_coste"])
        self.assertTrue(datos["relaciones_no_automaticas"])
        self.assertEqual(datos["incidencia"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Sesión sin contratiempos.")

    def test_cadena_recoger_evaluar_render(self) -> None:
        """Verifica que los datos obtenidos por recoger_datos se consumen correctamente en evaluar_gate y render_markdown."""
        secuencia_input = [
            "User513",  # tester
            "Windows 11",  # plataforma
            "sha_build_513",  # build_sha
            # 4 folios
            "s", "s", "s", "s", "captura_f.png", "nota f",
            "s", "s", "s", "s", "captura_m.png", "nota m",
            "s", "s", "s", "s", "captura_e.png", "nota e",
            "s", "s", "s", "s", "captura_a.png", "nota a",
            # Comprobaciones cruzadas
            "s",  # gatillo_memo_ok
            "s",  # gatillo_ficha_ok
            "s",  # peritaje_no_conclusion
            "s",  # acta_no_conclusion
            "s",  # relectura_sin_coste
            "s",  # relaciones_no_automaticas
            # Incidencia
            "Sin incidencias",
            # Observaciones
            "Todo correcto",
        ]

        with patch("builtins.input", side_effect=secuencia_input):
            datos = recoger_datos()

        gate = evaluar_gate(datos)
        self.assertTrue(gate["folios_ok"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["gatillos_ok"])
        self.assertTrue(gate["semantica_ok"])
        self.assertTrue(gate["economia_ok"])
        self.assertTrue(gate["relaciones_ok"])
        self.assertTrue(gate["listo_para_cerrar"])

        markdown = render_markdown(datos)
        self.assertIn("# Registro de playtest visual · #513", markdown)
        self.assertIn("tester/facilitador: User513", markdown)
        self.assertIn("plataforma: Windows 11", markdown)
        self.assertIn("build SHA: `sha_build_513`", markdown)
        for folio, _tipo in FOLIOS:
            self.assertIn(folio, markdown)
        self.assertIn("Sin incidencias", markdown)
        self.assertIn("Todo correcto", markdown)
        self.assertIn("listo para valorar cierre de #513: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
