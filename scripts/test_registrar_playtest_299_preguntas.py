from io import StringIO
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_299 as playtest  # noqa: E402


class TestPreguntar(unittest.TestCase):
    def test_preguntar_respuesta_valida(self):
        with patch("builtins.input", return_value="   respuesta_valida   "):
            res = playtest.preguntar("Ingrese alias: ")
            self.assertEqual(res, "respuesta_valida")

    def test_preguntar_repite_si_vacio(self):
        respuestas = ["", "   ", "\t", "  valor_correcto  "]
        with patch("builtins.input", side_effect=respuestas), patch(
            "sys.stdout", new_callable=StringIO
        ) as mock_stdout:
            res = playtest.preguntar("Ingrese alias: ")
            self.assertEqual(res, "valor_correcto")
            stdout_val = mock_stdout.getvalue()
            self.assertEqual(stdout_val.count("La respuesta no puede quedar vacía."), 3)


class TestPreguntarSiNo(unittest.TestCase):
    def test_preguntar_si_no_respuestas_afirmativas(self):
        for afirmativa in ["s", "S", "si", "SI", "sí", "SÍ", "  s  ", "  Sí  "]:
            with self.subTest(afirmativa=afirmativa):
                with patch("builtins.input", return_value=afirmativa):
                    self.assertTrue(playtest.preguntar_si_no("¿Pregunta?"))

    def test_preguntar_si_no_respuestas_negativas(self):
        for negativa in ["n", "N", "no", "NO", "  n  ", "  No  "]:
            with self.subTest(negativa=negativa):
                with patch("builtins.input", return_value=negativa):
                    self.assertFalse(playtest.preguntar_si_no("¿Pregunta?"))

    def test_preguntar_si_no_repite_si_invalido(self):
        respuestas = ["maybe", "123", "x", "s"]
        with patch("builtins.input", side_effect=respuestas), patch(
            "sys.stdout", new_callable=StringIO
        ) as mock_stdout:
            res = playtest.preguntar_si_no("¿Pregunta?")
            self.assertTrue(res)
            stdout_val = mock_stdout.getvalue()
            self.assertEqual(stdout_val.count("Responde s o n."), 3)


class TestPreguntarEntero(unittest.TestCase):
    def test_preguntar_entero_respuesta_valida(self):
        with patch("builtins.input", return_value="  42  "):
            res = playtest.preguntar_entero("Ingresar segundos: ", minimo=0)
            self.assertEqual(res, 42)

    def test_preguntar_entero_repite_si_no_es_entero(self):
        respuestas = ["abc", "12.5", "", "  15  "]
        with patch("builtins.input", side_effect=respuestas), patch(
            "sys.stdout", new_callable=StringIO
        ) as mock_stdout:
            res = playtest.preguntar_entero("Ingresar segundos: ")
            self.assertEqual(res, 15)
            stdout_val = mock_stdout.getvalue()
            self.assertEqual(stdout_val.count("Introduce un número entero."), 3)

    def test_preguntar_entero_repite_si_menor_al_minimo(self):
        respuestas = ["-5", "2", "10"]
        with patch("builtins.input", side_effect=respuestas), patch(
            "sys.stdout", new_callable=StringIO
        ) as mock_stdout:
            res = playtest.preguntar_entero("Ingresar valor: ", minimo=5)
            self.assertEqual(res, 10)
            stdout_val = mock_stdout.getvalue()
            self.assertIn("El valor mínimo es 5.", stdout_val)


class TestRecogerDatos(unittest.TestCase):
    def test_recoger_datos_y_encadenar_evaluar_render(self):
        inputs = [
            # participante (con repetición si vacío)
            "",
            "tester_299",
            # plataforma
            "Linux Ubuntu",
            # build_sha
            "abc299sha",
            # conocimiento_previo (s/n)
            "invalido",
            "n",
            # relato
            "Exploró de noche, activó 2 objetivos y despertó.",
            # segundos_primer_objetivo (entero)
            "invalido",
            "-1",
            "35",
            # ayuda_primer_objetivo
            "n",
            # estado_0_2_legible
            "s",
            # feedback_1_2
            "s",
            # guia_pendiente_legible
            "s",
            # sin_doble_conteo
            "s",
            # transicion_2_2
            "s",
            # transicion_unica
            "s",
            # opcional_no_bloquea
            "s",
            # temporizador_alternativo
            "s",
            # persistencia_ok
            "s",
            # incidencia_invalidante
            "n",
            # incidencia (opcional)
            "Ninguna",
            # observaciones (opcional)
            "Pase fluido",
        ]

        with patch("builtins.input", side_effect=inputs), patch(
            "sys.stdout", new_callable=StringIO
        ):
            datos = playtest.recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["participante"], "tester_299")
        self.assertEqual(datos["plataforma"], "Linux Ubuntu")
        self.assertEqual(datos["build_sha"], "abc299sha")
        self.assertFalse(datos["conocimiento_previo"])
        self.assertEqual(
            datos["relato"], "Exploró de noche, activó 2 objetivos y despertó."
        )
        self.assertEqual(datos["segundos_primer_objetivo"], 35)
        self.assertFalse(datos["ayuda_primer_objetivo"])
        self.assertTrue(datos["estado_0_2_legible"])
        self.assertTrue(datos["feedback_1_2"])
        self.assertTrue(datos["guia_pendiente_legible"])
        self.assertTrue(datos["sin_doble_conteo"])
        self.assertTrue(datos["transicion_2_2"])
        self.assertTrue(datos["transicion_unica"])
        self.assertTrue(datos["opcional_no_bloquea"])
        self.assertTrue(datos["temporizador_alternativo"])
        self.assertTrue(datos["persistencia_ok"])
        self.assertFalse(datos["incidencia_invalidante"])
        self.assertEqual(datos["incidencia"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Pase fluido")

        # Encadenar evaluar_gate
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["sin_ayuda_primer_objetivo"])
        self.assertTrue(gate["primero_menos_60"])
        self.assertTrue(gate["estado_0_2_legible"])
        self.assertTrue(gate["feedback_1_2"])
        self.assertTrue(gate["guia_pendiente_legible"])
        self.assertTrue(gate["sin_doble_conteo"])
        self.assertTrue(gate["transicion_2_2"])
        self.assertTrue(gate["transicion_unica"])
        self.assertTrue(gate["opcional_no_bloquea"])
        self.assertTrue(gate["temporizador_alternativo"])
        self.assertTrue(gate["persistencia_ok"])
        self.assertTrue(gate["sin_incidencia_invalidante"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

        # Encadenar render_markdown
        markdown = playtest.render_markdown(datos)
        self.assertIn("# Registro de playtest humano · #299", markdown)
        self.assertIn("- participante: tester_299", markdown)
        self.assertIn("- plataforma: Linux Ubuntu", markdown)
        self.assertIn("build SHA: `abc299sha`", markdown)
        self.assertIn("Tiempo hasta el primer objetivo válido: **35 s**", markdown)
        self.assertIn("Ninguna", markdown)
        self.assertIn("Pase fluido", markdown)
        self.assertIn("listo para valorar cierre de #299: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
