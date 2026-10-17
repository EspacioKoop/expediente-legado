from io import StringIO
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_276 as playtest  # noqa: E402


class TestPreguntar(unittest.TestCase):
    @patch("builtins.input", return_value="  respuesta valida  ")
    def test_preguntar_retorna_cadena_limpia(self, mock_input):
        resultado = playtest.preguntar("Prompt: ")
        self.assertEqual(resultado, "respuesta valida")
        mock_input.assert_called_once_with("Prompt: ")

    @patch("sys.stdout", new_callable=StringIO)
    @patch("builtins.input", side_effect=["", "   ", "  \n  ", " respuesta "])
    def test_preguntar_repite_hasta_obtener_valor_no_vacio(self, mock_input, mock_stdout):
        resultado = playtest.preguntar("Prompt: ")
        self.assertEqual(resultado, "respuesta")
        self.assertEqual(mock_input.call_count, 4)
        output = mock_stdout.getvalue()
        self.assertEqual(output.count("La respuesta no puede quedar vacía."), 3)


class TestPreguntarSiNo(unittest.TestCase):
    def test_respuestas_afirmativas(self):
        respuestas = ["s", "si", "sí", "S", "SI", "SÍ", "  s  "]
        for resp in respuestas:
            with self.subTest(respuesta=resp):
                with patch("builtins.input", return_value=resp):
                    self.assertTrue(playtest.preguntar_si_no("¿Pregunta?"))

    def test_respuestas_negativas(self):
        respuestas = ["n", "no", "N", "NO", "  n  "]
        for resp in respuestas:
            with self.subTest(respuesta=resp):
                with patch("builtins.input", return_value=resp):
                    self.assertFalse(playtest.preguntar_si_no("¿Pregunta?"))

    @patch("sys.stdout", new_callable=StringIO)
    @patch("builtins.input", side_effect=["tal vez", "123", "", "s"])
    def test_preguntar_si_no_repite_ante_entrada_invalida(self, mock_input, mock_stdout):
        resultado = playtest.preguntar_si_no("¿Aceptas?")
        self.assertTrue(resultado)
        self.assertEqual(mock_input.call_count, 4)
        output = mock_stdout.getvalue()
        self.assertEqual(output.count("Responde s o n."), 3)


class TestRecogerDatosYPipeline(unittest.TestCase):
    @patch("sys.stdout", new_callable=StringIO)
    @patch(
        "builtins.input",
        side_effect=[
            # preguntas textuales obligatorias (con reintentos)
            "",
            "tester_276",  # participante
            "Linux x86_64",  # plataforma
            "abc123sha",  # build_sha
            "Teclado y ratón",  # control
            "",
            "http://evidencia.local/frontal.png",  # evidencia_frontal
            "http://evidencia.local/lateral.png",  # evidencia_lateral
            "http://evidencia.local/reduccion.mp4",  # evidencia_reduccion
            # 10 preguntas si/no (con reintentos)
            "invalid",
            "s",  # export_real
            "s",  # frontal_atribucion_inmediata
            "s",  # lateral_atribucion_inmediata
            "s",  # movimiento_durante_linea
            "s",  # dos_companeros_sin_ambiguedad
            "s",  # camara_restaura
            "s",  # sin_conflicto_hud
            "s",  # sonido_no_molesta
            "s",  # reduccion_movimiento_correcta
            "s",  # sin_incidencia_bloqueante
            # campos opcionales finales
            " Ninguna ",  # incidencia
            " Todo OK ",  # observaciones
        ],
    )
    def test_recoger_datos_encadenado_con_evaluar_y_render(self, mock_input, mock_stdout):
        datos = playtest.recoger_datos()

        self.assertEqual(datos["participante"], "tester_276")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "abc123sha")
        self.assertEqual(datos["control"], "Teclado y ratón")
        self.assertEqual(datos["evidencia_frontal"], "http://evidencia.local/frontal.png")
        self.assertEqual(datos["evidencia_lateral"], "http://evidencia.local/lateral.png")
        self.assertEqual(datos["evidencia_reduccion"], "http://evidencia.local/reduccion.mp4")
        self.assertTrue(datos["export_real"])
        self.assertTrue(datos["sin_incidencia_bloqueante"])
        self.assertEqual(datos["incidencia"], "Ninguna")
        self.assertEqual(datos["observaciones"], "Todo OK")
        self.assertIn("fecha", datos)

        # Encadenar evaluar_gate
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["issue_cerrable"])
        self.assertTrue(gate["evidencia_frontal"])
        self.assertTrue(gate["evidencia_lateral"])
        self.assertTrue(gate["evidencia_reduccion"])

        # Encadenar render_markdown
        markdown = playtest.render_markdown(datos)
        self.assertIn("# Registro de playtest · diálogo diegético #276", markdown)
        self.assertIn("tester_276", markdown)
        self.assertIn("http://evidencia.local/frontal.png", markdown)
        self.assertIn("#276 cerrable con esta evidencia: **SÍ**", markdown)


if __name__ == "__main__":
    unittest.main()
