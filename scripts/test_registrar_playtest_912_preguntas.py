#!/usr/bin/env python3
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_912 as playtest  # noqa: E402


class PreguntasPlaytest912Test(unittest.TestCase):
    @patch("builtins.input", side_effect=["", "  ", " Tester 912 "])
    def test_preguntar_repite_si_vacio_y_recorta_espacios(self, _mock_input):
        resultado = playtest.preguntar("Nombre: ")
        self.assertEqual(resultado, "Tester 912")

    @patch("builtins.input", side_effect=["invalid", "quizás", "s"])
    def test_preguntar_si_no_acepta_afirmativo_tras_reintentos(self, _mock_input):
        self.assertTrue(playtest.preguntar_si_no("¿Continuar?"))

    @patch("builtins.input", side_effect=["NO", "si"])
    def test_preguntar_si_no_variaciones_validas(self, mock_input):
        self.assertFalse(playtest.preguntar_si_no("¿Pregunta 1?"))
        mock_input.side_effect = ["sí"]
        self.assertTrue(playtest.preguntar_si_no("¿Pregunta 2?"))

    @patch("builtins.input", side_effect=["abc", "-1", "-10", "0", "15"])
    def test_preguntar_entero_valida_tipo_y_no_negativo(self, _mock_input):
        # "abc", "-1", "-10" son inválidos; "0" es válido.
        val1 = playtest.preguntar_entero("Metrica 1")
        self.assertEqual(val1, 0)

        # "15" es válido.
        val2 = playtest.preguntar_entero("Metrica 2")
        self.assertEqual(val2, 15)

    @patch("builtins.input")
    def test_recoger_datos_cadena_evaluar_registro_y_render_markdown(self, mock_input):
        # Secuencia de respuestas para recoger_datos
        respuestas = [
            # Encabezado principal (con reintento en tester)
            "",
            "Bob",  # tester
            "Linux",  # plataforma
            "abc912",  # build_sha
            "1920x1080",  # viewport
        ]

        # 7 encuentros
        # Para base (clave == 'base'):
        # 7 métricas enteras: 10, 5, 5, 2, 1, 3, 0
        # 0 ritual_cambio_decision (omitido para base)
        # 5 checks_encuentro (s, s, s, s, s)
        # evidencia, incidencias
        #
        # Para los 6 restantes (clave != 'base'):
        # 7 métricas enteras: 10, 5, 5, 2, 1, 3, 0
        # 1 ritual_cambio_decision (s)
        # 5 checks_encuentro (s, s, s, s, s)
        # evidencia, incidencias

        for i, (clave, _titulo) in enumerate(playtest.ENCUENTROS):
            # 7 métricas enteras
            respuestas.extend(["10", "5", "5", "2", "1", "3", "0"])
            if clave != "base":
                respuestas.append("s")  # ritual_cambio_decision
            # 5 checks_encuentro
            respuestas.extend(["s", "s", "s", "s", "s"])
            respuestas.append(f"http://evidencia.log/{i}")  # evidencia
            respuestas.append("Sin incidencias")  # incidencias

        # Cierre transversal
        respuestas.extend(
            [
                "s",  # matriz_teclado_completa
                "s",  # muestra_mando_fisico
                "Xbox Controller",  # mando_modelo
                "s",  # reduccion_movimiento_equivalente
                "s",  # sin_ritual_dominante_o_inutil
                "s",  # acciones_diferenciadas
                "Observaciones finales de la prueba",  # observaciones
            ]
        )

        mock_input.side_effect = respuestas

        datos = playtest.recoger_datos()

        self.assertEqual(datos["tester"], "Bob")
        self.assertEqual(datos["plataforma"], "Linux")
        self.assertEqual(datos["build_sha"], "abc912")
        self.assertEqual(datos["viewport"], "1920x1080")
        self.assertEqual(len(datos["encuentros"]), 7)

        # Evaluar registro (gate)
        gate = playtest.evaluar_registro(datos)
        self.assertTrue(gate["viewport_ok"])
        self.assertTrue(gate["matriz_completa"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["checks_ok"])
        self.assertTrue(gate["teclado_ok"])
        self.assertTrue(gate["mando_ok"])
        self.assertTrue(gate["reduccion_ok"])
        self.assertTrue(gate["balance_humano_ok"])
        self.assertTrue(gate["funciones_ok"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

        # Renderizar Markdown
        markdown = playtest.render_markdown(datos)
        self.assertIn("# Registro de playtest · Juicio por Combate #912", markdown)
        self.assertIn("tester/facilitador: Bob", markdown)
        self.assertIn("build SHA: `abc912`", markdown)
        self.assertIn("viewport: `1920x1080`", markdown)
        self.assertIn("http://evidencia.log/0", markdown)
        self.assertIn("listo para valorar cierre de #912:", markdown)
        self.assertIn("**SÍ**", markdown)
        self.assertIn("Observaciones finales de la prueba", markdown)


if __name__ == "__main__":
    unittest.main()
