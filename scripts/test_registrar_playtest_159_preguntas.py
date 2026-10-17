from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_159 as playtest  # noqa: E402


class TestRegistrarPlaytest159Preguntas(unittest.TestCase):
    """Pruebas unitarias para preguntar, preguntar_si_no y recoger_datos en registrar_playtest_159.py."""

    def test_preguntar_respuesta_valida_directa(self) -> None:
        """Verifica que preguntar devuelve la respuesta limpia cuando la primera entrada es válida."""
        with patch("builtins.input", return_value="  tester_mando_01  "):
            respuesta = playtest.preguntar("Alias del participante: ")
            self.assertEqual(respuesta, "tester_mando_01")

    def test_preguntar_repite_ante_entradas_vacias(self) -> None:
        """Verifica que preguntar ignora cadenas vacías o con solo espacios y repite hasta obtener un valor."""
        secuencia = ["", "   ", "\t", "  tester_mando_02  "]
        with patch("builtins.input", side_effect=secuencia), patch("builtins.print") as mock_print:
            respuesta = playtest.preguntar("Alias del participante: ")
            self.assertEqual(respuesta, "tester_mando_02")
            mock_print.assert_called_with("La respuesta no puede quedar vacía.")
            self.assertEqual(mock_print.call_count, 3)

    def test_preguntar_si_no_respuestas_afirmativas(self) -> None:
        """Verifica que preguntar_si_no reconoce s, si y sí en distintas variantes."""
        opciones_afirmativas = ["s", "S", " si ", "SI", "sí", "SÍ", "  s  ", "  Sí  "]
        for opcion in opciones_afirmativas:
            with self.subTest(opcion=opcion):
                with patch("builtins.input", return_value=opcion):
                    self.assertTrue(playtest.preguntar_si_no("¿Pregunta?"))

    def test_preguntar_si_no_respuestas_negativas(self) -> None:
        """Verifica que preguntar_si_no reconoce n y no en distintas variantes."""
        opciones_negativas = ["n", "N", " no ", "NO", "No", "  n  "]
        for opcion in opciones_negativas:
            with self.subTest(opcion=opcion):
                with patch("builtins.input", return_value=opcion):
                    self.assertFalse(playtest.preguntar_si_no("¿Pregunta?"))

    def test_preguntar_si_no_repite_ante_entradas_invalidas(self) -> None:
        """Verifica que preguntar_si_no repite la pregunta cuando recibe respuestas fuera de rango o vacías."""
        secuencia = ["quizás", "", "123", "tal vez", "s"]
        with patch("builtins.input", side_effect=secuencia), patch("builtins.print") as mock_print:
            resultado = playtest.preguntar_si_no("¿Pregunta?")
            self.assertTrue(resultado)
            mock_print.assert_called_with("Responde s o n.")
            self.assertEqual(mock_print.call_count, 4)

    def test_recoger_datos_y_encadenar_evaluar_gate_y_render_markdown(self) -> None:
        """Verifica que recoger_datos procesa la secuencia interactiva y que el diccionario resultante es consumible por evaluar_gate y render_markdown."""
        secuencia_input = [
            # participante (con reintento vacío)
            "",
            "  TesterMando  ",
            # plataforma
            "Linux x86_64",
            # build_sha
            "fedcba987654",
            # mando_modelo
            "DualSense Wireless Controller",
            # mando_familia
            "PlayStation",
            # conexion
            "cable",
            # remapeado (con reintento fuera de rango)
            "invalid_option",
            "n",  # False
            # 11 checks (todos afirmativos)
            "s",  # mando_detectado
            "si",  # entrada_solo_mando
            "sí",  # stick_apunta
            "s",  # cruceta_apunta
            "s",  # sin_deriva
            "s",  # boton_principal_lanza
            "s",  # dos_lanzamientos
            "s",  # boton_secundario_abandona
            "s",  # oficina_restaurada
            "s",  # repeticion_funciona
            "s",  # sin_incidencia_reproducible
            # incidencia (input opcional)
            "  Ninguna incidencia  ",
            # observaciones (input opcional)
            "  Pase sin fallos apreciables  ",
        ]

        with patch("builtins.input", side_effect=secuencia_input), patch("builtins.print"):
            datos = playtest.recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["participante"], "TesterMando")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "fedcba987654")
        self.assertEqual(datos["mando_modelo"], "DualSense Wireless Controller")
        self.assertEqual(datos["mando_familia"], "PlayStation")
        self.assertEqual(datos["conexion"], "cable")
        self.assertFalse(datos["remapeado"])
        self.assertTrue(datos["mando_detectado"])
        self.assertTrue(datos["entrada_solo_mando"])
        self.assertTrue(datos["stick_apunta"])
        self.assertTrue(datos["cruceta_apunta"])
        self.assertTrue(datos["sin_deriva"])
        self.assertTrue(datos["boton_principal_lanza"])
        self.assertTrue(datos["dos_lanzamientos"])
        self.assertTrue(datos["boton_secundario_abandona"])
        self.assertTrue(datos["oficina_restaurada"])
        self.assertTrue(datos["repeticion_funciona"])
        self.assertTrue(datos["sin_incidencia_reproducible"])
        self.assertEqual(datos["incidencia"], "Ninguna incidencia")
        self.assertEqual(datos["observaciones"], "Pase sin fallos apreciables")

        # Encadenamiento con evaluar_gate
        gate = playtest.evaluar_gate(datos)
        for check in playtest.CHECKS:
            self.assertTrue(gate[check])
        self.assertTrue(gate["listo_para_cerrar_mando"])

        # Encadenamiento con render_markdown
        markdown = playtest.render_markdown(datos)
        self.assertIn("# Registro de playtest físico de mando · #159", markdown)
        self.assertIn("- participante: TesterMando", markdown)
        self.assertIn("- plataforma: Linux x86_64", markdown)
        self.assertIn("- build SHA: `fedcba987654`", markdown)
        self.assertIn("- mando: DualSense Wireless Controller", markdown)
        self.assertIn("Ninguna incidencia", markdown)
        self.assertIn("Pase sin fallos apreciables", markdown)
        self.assertIn("gate físico de mando de #159: **CUMPLE**", markdown)


if __name__ == "__main__":
    unittest.main()
