from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock

RAIZ = Path(__file__).resolve().parents[1]
SCRIPTS = RAIZ / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

import agent_preflight as preflight


class EsGodotAusenteTest(unittest.TestCase):
    def test_detecta_godot_ausente_con_binario_por_defecto(self):
        binario = "godot4"
        traza = (
            "Traceback (most recent call last):\n"
            "  File 'test.py', line 10, in test_run\n"
            "FileNotFoundError: [Errno 2] No such file or directory: 'godot4'\n"
        )
        self.assertTrue(preflight.es_godot_ausente(traza, binario))

    def test_detecta_godot_ausente_con_binario_personalizado(self):
        binario = "godot-custom-bin"
        traza = f"FileNotFoundError: [Errno 2] No such file or directory: '{binario}'"
        self.assertTrue(preflight.es_godot_ausente(traza, binario))

    def test_ignora_traza_sin_fichero_ausente(self):
        binario = "godot4"
        traza = "AssertionError: 1 != 2\n"
        self.assertFalse(preflight.es_godot_ausente(traza, binario))

    def test_ignora_fichero_ausente_de_otro_binario(self):
        binario = "godot4"
        traza = "FileNotFoundError: [Errno 2] No such file or directory: 'otro_binario'"
        self.assertFalse(preflight.es_godot_ausente(traza, binario))


class ComprobarGdTest(unittest.TestCase):
    def test_lista_vacia_no_ejecuta_herramientas(self):
        with mock.patch.object(preflight.shutil, "which") as mock_which, mock.patch.object(
            preflight.subprocess, "run"
        ) as mock_run:
            resultado = preflight.comprobar_gd([], raiz=RAIZ)

        self.assertEqual({"archivos": [], "problemas": []}, resultado)
        mock_which.assert_not_called()
        mock_run.assert_not_called()

    def test_binario_ausente_registra_problema_de_herramienta_no_disponible(self):
        with mock.patch.object(preflight.shutil, "which", return_value=None):
            resultado = preflight.comprobar_gd(["godot/escena.gd"], raiz=RAIZ)

        self.assertEqual(["godot/escena.gd"], resultado["archivos"])
        self.assertEqual(2, len(resultado["problemas"]))
        self.assertIn("gdformat no disponible", resultado["problemas"][0])
        self.assertIn("gdlint no disponible", resultado["problemas"][1])

    def test_error_de_parseo_o_lint_registra_traza_de_problemas(self):
        with mock.patch.object(
            preflight.shutil, "which", return_value="/usr/local/bin/gdtool"
        ), mock.patch.object(
            preflight.subprocess,
            "run",
            side_effect=[
                subprocess.CompletedProcess(
                    args=["gdformat"],
                    returncode=1,
                    stdout="",
                    stderr="ParseError: line 5: unexpected token: 'func_invalid'\n",
                ),
                subprocess.CompletedProcess(
                    args=["gdlint"],
                    returncode=1,
                    stdout="godot/escena.gd:5: error: StandaloneExpression\n",
                    stderr="",
                ),
            ],
        ) as mock_run:
            resultado = preflight.comprobar_gd(["godot/escena.gd"], raiz=RAIZ)

        self.assertEqual(["godot/escena.gd"], resultado["archivos"])
        self.assertEqual(2, len(resultado["problemas"]))
        self.assertIn("gdformat: ParseError: line 5: unexpected token", resultado["problemas"][0])
        self.assertIn("gdlint: godot/escena.gd:5: error: StandaloneExpression", resultado["problemas"][1])
        self.assertEqual(2, mock_run.call_count)

    def test_comprobacion_exitosa_sin_problemas(self):
        with mock.patch.object(
            preflight.shutil, "which", return_value="/usr/local/bin/gdtool"
        ), mock.patch.object(
            preflight.subprocess,
            "run",
            return_value=subprocess.CompletedProcess(
                args=["gdtool"], returncode=0, stdout="", stderr=""
            ),
        ) as mock_run:
            resultado = preflight.comprobar_gd(["godot/escena.gd"], raiz=RAIZ)

        self.assertEqual({"archivos": ["godot/escena.gd"], "problemas": []}, resultado)
        self.assertEqual(2, mock_run.call_count)


if __name__ == "__main__":
    unittest.main()
