#!/usr/bin/env python3
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_431 as playtest  # noqa: E402


class PreguntasPlaytest431Test(unittest.TestCase):
    @patch("builtins.input", side_effect=["", "  ", " Tester 1 "])
    def test_preguntar_repite_si_vacio_y_recorta_espacios(self, _mock_input):
        resultado = playtest.preguntar("Nombre: ")
        self.assertEqual(resultado, "Tester 1")

    @patch("builtins.input", side_effect=["invalid", "tal vez", "s"])
    def test_preguntar_si_no_acepta_afirmativo_tras_reintentos(self, _mock_input):
        self.assertTrue(playtest.preguntar_si_no("¿Continuar?"))

    @patch("builtins.input", side_effect=["NO", "si"])
    def test_preguntar_si_no_variaciones_validas(self, mock_input):
        self.assertFalse(playtest.preguntar_si_no("¿Pregunta 1?"))
        mock_input.side_effect = ["sí"]
        self.assertTrue(playtest.preguntar_si_no("¿Pregunta 2?"))

    @patch("builtins.input", side_effect=["abc", "-1", "0", "5"])
    def test_preguntar_entero_valida_tipo_y_minimo(self, _mock_input):
        # Para minimo=0, "-1" es menor que minimo; "0" es válido.
        val1 = playtest.preguntar_entero("Numero (min 0): ", minimo=0)
        self.assertEqual(val1, 0)

        # Para minimo=5, "5" es válido.
        val2 = playtest.preguntar_entero("Numero (min 5): ", minimo=5)
        self.assertEqual(val2, 5)

    @patch("builtins.input", side_effect=["invalido", "LIGERA"])
    def test_preguntar_impresion_obtiene_clave_valida(self, _mock_input):
        impresion = playtest.preguntar_impresion()
        self.assertEqual(impresion, "ligera")

    @patch("builtins.input")
    def test_recoger_datos_cadena_evaluar_gate_y_render_markdown(self, mock_input):
        respuestas = [
            # Datos iniciales (con reintento en tester)
            "",
            "Alice",  # tester
            "Linux",  # plataforma
            "sha123",  # build_sha
            "invalid_s_n",
            "s",  # teclado_real
            "s",  # mando_fisico
            "Xbox Pad",  # mando_modelo
            # Expediente 1
            "EXP-001",  # nombre
            "2",  # folios_abiertos
            "s",  # relectura_voluntaria
            "1",  # intentos_relacion
            "s",  # marcador_usado
            "s",  # anexo_usado
            "Nota expediente 1",  # nota
            # Expediente 2
            "EXP-002",  # nombre
            "3",  # folios_abiertos
            "s",  # relectura_voluntaria
            "0",  # intentos_relacion
            "s",  # marcador_usado
            "s",  # anexo_usado
            "Nota expediente 2",  # nota
            # Capas (4 capas: relacion, marcador, metadatos, anexo)
            # Para relacion: usada=s, sin_ayuda=s
            "s",
            "s",
            # Para marcador: usada=s, sin_ayuda=s
            "s",
            "s",
            # Para metadatos: usada=n
            "n",
            # Para anexo: usada=n
            "n",
            # Relaciones
            "s",  # relacion_valida
            "s",  # relacion_invalida_prudente
            "s",  # feedback_pareja_entendido
            # Persistencia
            "s",  # persisten_lecturas
            "s",  # persisten_marcadores
            "s",  # persisten_relaciones
            # Careo y cierre
            "s",  # contexto_careo_visible
            "s",  # careo_no_automatizado
            "s",  # sin_hueco_paridad_sin_issue
            "ligera",  # impresion
            "http://evidencia.log",  # evidencia
            "Ninguna",  # incidencias
        ]
        mock_input.side_effect = respuestas

        datos = playtest.recoger_datos()

        self.assertEqual(datos["tester"], "Alice")
        self.assertEqual(datos["plataforma"], "Linux")
        self.assertEqual(datos["build_sha"], "sha123")
        self.assertTrue(datos["teclado_real"])
        self.assertTrue(datos["mando_fisico"])
        self.assertEqual(datos["mando_modelo"], "Xbox Pad")
        self.assertEqual(len(datos["casos"]), 2)

        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["dos_casos_ok"])
        self.assertTrue(gate["capas_ok"])
        self.assertTrue(gate["relacion_ok"])
        self.assertTrue(gate["persistencia_ok"])
        self.assertTrue(gate["careo_ok"])
        self.assertTrue(gate["paridad_ok"])
        self.assertTrue(gate["experiencia_ok"])
        self.assertTrue(gate["teclado_ok"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

        markdown = playtest.render_markdown(datos)
        self.assertIn("# Registro de playtest SIGA · #431 / #286", markdown)
        self.assertIn("tester/facilitador: Alice", markdown)
        self.assertIn("build SHA: `sha123`", markdown)
        self.assertIn("EXP-001", markdown)
        self.assertIn("EXP-002", markdown)
        self.assertIn("http://evidencia.log", markdown)
        self.assertIn("listo para valorar cierre de #286: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
