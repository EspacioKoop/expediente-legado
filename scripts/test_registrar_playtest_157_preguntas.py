from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_157 as playtest  # noqa: E402


class TestRegistrarPlaytest157Preguntas(unittest.TestCase):
    @patch("builtins.print")
    def test_preguntar_acepta_respuesta_valida(self, _mock_print):
        with patch("builtins.input", return_value="  tester1  "):
            res = playtest.preguntar("Alias: ")
            self.assertEqual(res, "tester1")

    @patch("builtins.print")
    def test_preguntar_repite_si_respuesta_esta_vacia(self, mock_print):
        respuestas = ["", "   ", "  participante_ok  "]
        with patch("builtins.input", side_effect=respuestas):
            res = playtest.preguntar("Alias: ")
            self.assertEqual(res, "participante_ok")
            self.assertEqual(mock_print.call_count, 2)
            mock_print.assert_called_with("La respuesta no puede quedar vacía.")

    @patch("builtins.print")
    def test_preguntar_si_no_acepta_afirmativas_y_negativas(self, _mock_print):
        casos_si = ["s", "S", "si", "SI", "sí", "Sí"]
        for entrada in casos_si:
            with self.subTest(entrada=entrada):
                with patch("builtins.input", return_value=entrada):
                    self.assertTrue(playtest.preguntar_si_no("¿Pregunta?"))

        casos_no = ["n", "N", "no", "NO"]
        for entrada in casos_no:
            with self.subTest(entrada=entrada):
                with patch("builtins.input", return_value=entrada):
                    self.assertFalse(playtest.preguntar_si_no("¿Pregunta?"))

    @patch("builtins.print")
    def test_preguntar_si_no_repite_si_respuesta_fuera_de_rango(self, mock_print):
        respuestas = ["tal vez", "", "123", "s"]
        with patch("builtins.input", side_effect=respuestas):
            res = playtest.preguntar_si_no("¿Pregunta?")
            self.assertTrue(res)
            self.assertEqual(mock_print.call_count, 3)
            mock_print.assert_called_with("Responde s o n.")

    @patch("builtins.print")
    def test_recoger_datos_secuencia_completa_y_encadenamiento(self, _mock_print):
        respuestas_secuencia = [
            # 5 datos iniciales con preguntar (incluyendo vacíos que obligan a repetir)
            "",
            "tester-humano",  # participante
            "Linux x86_64",  # plataforma
            "",
            "sha12345",  # build_sha
            "Gamepad Pro",  # mando_modelo
            "cable USB",  # conexion
            # 12 checks con preguntar_si_no (incluyendo respuestas inválidas)
            "invalido",
            "s",  # dos_carpetas = True
            "si",  # recogida_clara = True
            "sí",  # error_no_destruye = True
            "s",  # correccion_funciona = True
            "s",  # siguiente_carpeta = True
            "s",  # abandono_persiste = True
            "s",  # jornada_continua = True
            "s",  # rehidratacion_comprensible = True
            "s",  # precision_visible = True
            "s",  # mando_fisico = True
            "s",  # foco_mando = True
            "s",  # sin_incidencia_bloqueante = True
            # 2 inputs opcionales
            "Sin incidencias bloqueantes.",  # incidencia
            "Todo correcto en el pase.",  # observaciones
        ]

        with patch("builtins.input", side_effect=respuestas_secuencia):
            datos = playtest.recoger_datos()

        self.assertIn("fecha", datos)
        self.assertEqual(datos["participante"], "tester-humano")
        self.assertEqual(datos["plataforma"], "Linux x86_64")
        self.assertEqual(datos["build_sha"], "sha12345")
        self.assertEqual(datos["mando_modelo"], "Gamepad Pro")
        self.assertEqual(datos["conexion"], "cable USB")
        self.assertTrue(datos["dos_carpetas"])
        self.assertTrue(datos["sin_incidencia_bloqueante"])
        self.assertEqual(datos["incidencia"], "Sin incidencias bloqueantes.")
        self.assertEqual(datos["observaciones"], "Todo correcto en el pase.")

        # Encadenar evaluar_gate y render_markdown
        gate = playtest.evaluar_gate(datos)
        self.assertTrue(gate["listo_para_cerrar_gate_humano"])

        markdown = playtest.render_markdown(datos)
        self.assertIn("participante: tester-humano", markdown)
        self.assertIn("build SHA: `sha12345`", markdown)
        self.assertIn("gate humano de #157: **CUMPLE**", markdown)
        self.assertIn("Sin incidencias bloqueantes.", markdown)
        self.assertIn("Todo correcto en el pase.", markdown)


if __name__ == "__main__":
    unittest.main()
