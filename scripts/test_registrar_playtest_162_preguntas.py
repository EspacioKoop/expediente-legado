from io import StringIO
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_162 as playtest  # noqa: E402


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


class TestRecogerDatos(unittest.TestCase):
    def test_recoger_datos_y_encadenar_evaluar_render(self):
        inputs = [
            # participante (first empty, then valid)
            "",
            "tester_alpha",
            # plataforma
            "Linux Ubuntu",
            # build_sha
            "abc1234",
            # mando_modelo
            "DualSense",
            # 12 checks (mix of valid s/n, with invalid retry for first check)
            "invalido",
            "s",  # ui_tres_huecos
            "s",  # foco_teclado_mando
            "s",  # seleccion_vacia_segura
            "s",  # repeticion_visible
            "s",  # relacion_conocida_visible
            "s",  # selecciones_distintas_visibles
            "s",  # recarga_determinista
            "s",  # sin_documentos_desconocidos
            "s",  # salida_segura
            "s",  # sin_recompensa_mecanica
            "s",  # mando_fisico
            "s",  # sin_incidencia_bloqueante
            # contradicciones_canonicas_resueltas
            "s",
            # fuente_contradicciones
            "doc/contradicciones.md@v1.0",
            # incidencia
            "  Ninguna  ",
            # observaciones
            "  Pase excelente  ",
        ]

        with patch("builtins.input", side_effect=inputs), patch(
            "sys.stdout", new_callable=StringIO
        ):
            datos = playtest.recoger_datos()

        self.assertEqual(datos["participante"], "tester_alpha")
        self.assertEqual(datos["plataforma"], "Linux Ubuntu")
        self.assertEqual(datos["build_sha"], "abc1234")
        self.assertEqual(datos["mando_modelo"], "DualSense")
        self.assertTrue(datos["ui_tres_huecos"])
        self.assertTrue(datos["contradicciones_canonicas_resueltas"])
        self.assertEqual(datos["fuente_contradicciones"], "doc/contradicciones.md@v1.0")
        self.assertEqual(datos["incidencia"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Pase excelente")

        # Encadenar evaluar_gate y render_markdown
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["gate_visual_mando"])
        self.assertTrue(gate["contradicciones_canonicas_resueltas"])
        self.assertTrue(gate["issue_completamente_cerrable"])

        markdown = playtest.render_markdown(datos)
        self.assertIn("- participante: tester_alpha", markdown)
        self.assertIn("build SHA: `abc1234`", markdown)
        self.assertIn("#162 completamente cerrable: **SÍ**", markdown)

    def test_recoger_datos_sin_contradicciones_resueltas(self):
        inputs = [
            "tester_beta",
            "Windows 11",
            "def5678",
            "Xbox Controller",
            # 12 checks: all s
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            "s",
            # contradicciones_canonicas_resueltas: False
            "n",
            # fuente_contradicciones NOT asked when False!
            # incidencia (optional)
            "",
            # observaciones (optional)
            "",
        ]

        with patch("builtins.input", side_effect=inputs), patch(
            "sys.stdout", new_callable=StringIO
        ):
            datos = playtest.recoger_datos()

        self.assertEqual(datos["participante"], "tester_beta")
        self.assertFalse(datos["contradicciones_canonicas_resueltas"])
        self.assertEqual(datos["fuente_contradicciones"], "")
        self.assertEqual(datos["incidencia"], "")
        self.assertEqual(datos["observaciones"], "")

        # Encadenar evaluar_gate y render_markdown
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["gate_visual_mando"])
        self.assertFalse(gate["contradicciones_canonicas_resueltas"])
        self.assertFalse(gate["issue_completamente_cerrable"])

        markdown = playtest.render_markdown(datos)
        self.assertIn("- participante: tester_beta", markdown)
        self.assertIn("Ninguna anotada.", markdown)
        self.assertIn("Sin observaciones adicionales.", markdown)
        self.assertIn("#162 completamente cerrable: **NO**", markdown)


if __name__ == "__main__":
    unittest.main()
