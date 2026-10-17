from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_cata_119 as cata  # noqa: E402


class TestRegistrarCata119Evaluacion(unittest.TestCase):
    def test_evaluar_fuente_promover_completo(self):
        datos = {
            "decision": "promover",
            "nivel_adecuado": True,
            "loop_limpio": True,
            "fatiga_aceptable": True,
            "legibilidad": True,
        }
        res = cata.evaluar_fuente(datos)
        self.assertTrue(res["decision_valida"])
        self.assertTrue(res["promover_listo"])
        self.assertFalse(res["requiere_iteracion"])
        self.assertFalse(res["descartada"])

    def test_evaluar_fuente_promover_incompleto_requiere_iteracion(self):
        datos = {
            "decision": "promover",
            "nivel_adecuado": True,
            "loop_limpio": False,
            "fatiga_aceptable": True,
            "legibilidad": True,
        }
        res = cata.evaluar_fuente(datos)
        self.assertTrue(res["decision_valida"])
        self.assertFalse(res["promover_listo"])
        self.assertTrue(res["requiere_iteracion"])
        self.assertFalse(res["descartada"])

    def test_evaluar_fuente_iterar(self):
        datos = {
            "decision": "iterar",
            "nivel_adecuado": True,
            "loop_limpio": True,
            "fatiga_aceptable": True,
            "legibilidad": True,
        }
        res = cata.evaluar_fuente(datos)
        self.assertTrue(res["decision_valida"])
        self.assertFalse(res["promover_listo"])
        self.assertTrue(res["requiere_iteracion"])
        self.assertFalse(res["descartada"])

    def test_evaluar_fuente_descartar(self):
        datos = {"decision": "descartar"}
        res = cata.evaluar_fuente(datos)
        self.assertTrue(res["decision_valida"])
        self.assertFalse(res["promover_listo"])
        self.assertFalse(res["requiere_iteracion"])
        self.assertTrue(res["descartada"])

    def test_evaluar_fuente_decision_invalida(self):
        datos = {"decision": "invalida"}
        res = cata.evaluar_fuente(datos)
        self.assertFalse(res["decision_valida"])
        self.assertFalse(res["promover_listo"])
        self.assertFalse(res["requiere_iteracion"])
        self.assertFalse(res["descartada"])

    @patch("builtins.input", side_effect=["", "   ", "Oyente Test"])
    def test_preguntar_reintenta_si_vacio(self, mock_input):
        respuesta = cata.preguntar("Alias: ")
        self.assertEqual(respuesta, "Oyente Test")
        self.assertEqual(mock_input.call_count, 3)

    @patch("builtins.input", side_effect=["quizás", "S", "NO"])
    def test_preguntar_si_no(self, mock_input):
        res_s = cata.preguntar_si_no("¿Pregunta 1?")
        self.assertTrue(res_s)
        res_n = cata.preguntar_si_no("¿Pregunta 2?")
        self.assertFalse(res_n)
        self.assertEqual(mock_input.call_count, 3)

    @patch("builtins.input", side_effect=["otra_cosa", "PROMOVER", "descartar"])
    def test_preguntar_decision(self, mock_input):
        res1 = cata.preguntar_decision("Fuente 1")
        self.assertEqual(res1, "promover")
        res2 = cata.preguntar_decision("Fuente 2")
        self.assertEqual(res2, "descartar")
        self.assertEqual(mock_input.call_count, 3)

    @patch("builtins.input")
    def test_recoger_datos(self, mock_input):
        inputs = [
            "Oyente Alpha",  # participante
            "Linux / Auriculares",  # plataforma
            "Artifact 123",  # artifact
            "abcdef1",  # build_ref
        ]
        # 4 fuentes en cata.FUENTES:
        # ("fluorescente_archivo", ...), ("teclado_oficina", ...), ("calle_nocturna", ...), ("sueno_onirico", ...)
        for _ in range(4):
            inputs.extend([
                "promover",  # decision
                "s",  # nivel_adecuado
                "s",  # loop_limpio
                "s",  # fatiga_aceptable
                "s",  # legibilidad
                "Sin observaciones",  # observacion
            ])
        mock_input.side_effect = inputs

        datos = cata.recoger_datos()

        self.assertEqual(datos["participante"], "Oyente Alpha")
        self.assertEqual(datos["plataforma"], "Linux / Auriculares")
        self.assertEqual(datos["artifact"], "Artifact 123")
        self.assertEqual(datos["build_ref"], "abcdef1")
        self.assertIn("fecha", datos)

        fuentes = datos["fuentes"]
        self.assertEqual(len(fuentes), 4)
        for clave, _ in cata.FUENTES:
            self.assertIn(clave, fuentes)
            fuente = fuentes[clave]
            self.assertEqual(fuente["decision"], "promover")
            self.assertTrue(fuente["nivel_adecuado"])
            self.assertTrue(fuente["loop_limpio"])
            self.assertTrue(fuente["fatiga_aceptable"])
            self.assertTrue(fuente["legibilidad"])
            self.assertEqual(fuente["observacion"], "Sin observaciones")


if __name__ == "__main__":
    unittest.main()
