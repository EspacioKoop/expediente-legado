import os
import json
from pathlib import Path
import tempfile
import subprocess
import sys
import textwrap
import unittest
from unittest import mock

import agent_preflight as preflight


def repo_falso(ficheros: dict[str, str]) -> tempfile.TemporaryDirectory:
    tmp = tempfile.TemporaryDirectory()
    for ruta, contenido in ficheros.items():
        destino = Path(tmp.name) / ruta
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_text(textwrap.dedent(contenido), encoding="utf-8")
    return tmp


class SeleccionTest(unittest.TestCase):
    def setUp(self):
        self.tmp = repo_falso(
            {
                "scripts/modulo.py": "X = 1\n",
                "scripts/test_modulo.py": "import modulo\n",
                "scripts/test_usa_modulo.py": "from modulo import X\n",
                "scripts/test_otro.py": "import modulo_distinto\n",
                "scripts/test_contrato_gd.py": 'RUTA = ROOT / "godot" / "guion" / "escena.gd"\n',
                "scripts/test_ruta_gd.py": 'TEXTO = "godot/guion/escena.gd"\n',
                "godot/guion/escena.gd": "extends Node\n",
            }
        )
        self.raiz = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_modulo_python_arrastra_su_test_y_los_que_lo_importan(self):
        self.assertEqual(
            ["test_modulo.py", "test_usa_modulo.py"],
            preflight.tests_relacionados(["scripts/modulo.py"], self.raiz),
        )

    def test_test_cambiado_se_ejecuta_el_mismo(self):
        self.assertEqual(["test_otro.py"], preflight.tests_relacionados(["scripts/test_otro.py"], self.raiz))

    def test_gd_arrastra_contratos_que_lo_citan(self):
        self.assertEqual(
            ["test_contrato_gd.py", "test_ruta_gd.py"],
            preflight.tests_relacionados(["godot/guion/escena.gd"], self.raiz),
        )

    def test_rutas_ajenas_no_seleccionan_nada(self):
        self.assertEqual([], preflight.tests_relacionados(["docs/x.md", "godot/datos/y.json"], self.raiz))


class EjecucionTest(unittest.TestCase):
    def ejecutar(self, cuerpo_test: str):
        tmp = repo_falso({"scripts/test_caso.py": cuerpo_test})
        self.addCleanup(tmp.cleanup)
        with mock.patch.dict(os.environ, {"GODOT_BIN": "godot-no-existe-1636"}):
            return preflight.ejecutar_tests(["test_caso.py"], Path(tmp.name))

    def test_falta_de_godot_se_omite_y_no_falla(self):
        resultado = self.ejecutar(
            """
            import subprocess, unittest
            class T(unittest.TestCase):
                def test_lanza_godot(self):
                    subprocess.run(["godot-no-existe-1636", "--version"], check=True)
                def test_normal(self):
                    self.assertTrue(True)
            """
        )
        self.assertEqual(2, resultado["ejecutados"])
        self.assertEqual(1, len(resultado["sin_godot"]))
        self.assertEqual([], resultado["errores"])
        self.assertEqual([], resultado["fallos"])

    def test_otros_errores_y_fallos_son_reales(self):
        resultado = self.ejecutar(
            """
            import subprocess, unittest
            class T(unittest.TestCase):
                def test_otro_binario(self):
                    subprocess.run(["binario-ajeno-1636"], check=True)
                def test_falla(self):
                    self.assertEqual(1, 2)
            """
        )
        self.assertEqual([], resultado["sin_godot"])
        self.assertEqual(1, len(resultado["errores"]))
        self.assertEqual(1, len(resultado["fallos"]))

    def test_unexpected_success_se_conserva_en_informe(self):
        resultado = self.ejecutar(
            """
            import unittest
            class T(unittest.TestCase):
                @unittest.expectedFailure
                def test_pasa_inesperadamente(self):
                    self.assertTrue(True)
            """
        )
        self.assertEqual(1, len(resultado["exitos_inesperados"]))
        self.assertIn("test_pasa_inesperadamente", resultado["exitos_inesperados"][0])


class PreflightTest(unittest.TestCase):
    def test_expected_failure_legitimo_conserva_ok(self):
        tmp = repo_falso({"scripts/test_caso.py": """
            import unittest
            class T(unittest.TestCase):
                @unittest.expectedFailure
                def test_falla_como_se_espera(self):
                    self.assertEqual(1, 2)
        """})
        self.addCleanup(tmp.cleanup)
        informe = preflight.preflight(["scripts/test_caso.py"], Path(tmp.name))
        self.assertTrue(informe["ok"])
        self.assertEqual([], informe["python"]["exitos_inesperados"])

    def test_unexpected_success_falla_preflight_y_cli_real(self):
        tmp = repo_falso({"scripts/test_caso.py": """
            import unittest
            class T(unittest.TestCase):
                @unittest.expectedFailure
                def test_pasa_inesperadamente(self):
                    self.assertTrue(True)
        """})
        self.addCleanup(tmp.cleanup)
        raiz = Path(tmp.name)
        informe = preflight.preflight(["scripts/test_caso.py"], raiz)
        self.assertFalse(informe["ok"])
        self.assertEqual(1, len(informe["python"]["exitos_inesperados"]))

        script = raiz / "scripts/agent_preflight.py"
        script.write_text(Path(preflight.__file__).read_text(encoding="utf-8"), encoding="utf-8")
        reporte = raiz / "informe.json"
        resultado = subprocess.run(
            [sys.executable, str(script), "--changed", "scripts/test_caso.py",
             "--report", str(reporte)],
            cwd=raiz, capture_output=True, text=True, timeout=10,
        )
        self.assertEqual(1, resultado.returncode, resultado.stdout + resultado.stderr)
        self.assertIn("exitos_inesperados=1", resultado.stdout)
        self.assertIn("test_pasa_inesperadamente", resultado.stdout)
        self.assertFalse(json.loads(reporte.read_text())["ok"])

    def test_diff_sin_tests_ni_gd_es_ok(self):
        tmp = repo_falso({"docs/x.md": "hola\n"})
        self.addCleanup(tmp.cleanup)
        informe = preflight.preflight(["docs/x.md"], Path(tmp.name))
        self.assertTrue(informe["ok"])
        self.assertEqual(0, informe["python"]["ejecutados"])

    def test_gd_sin_gdtoolkit_no_pasa_en_silencio(self):
        tmp = repo_falso({"godot/a.gd": "extends Node\n"})
        self.addCleanup(tmp.cleanup)
        with mock.patch.object(preflight.shutil, "which", return_value=None):
            informe = preflight.preflight(["godot/a.gd"], Path(tmp.name))
        self.assertFalse(informe["ok"])
        self.assertTrue(any("gdformat no disponible" in p for p in informe["gd"]["problemas"]))

    def test_demasiados_tests_se_delegan_al_ci(self):
        ficheros = {"scripts/comun.py": "X = 1\n"}
        for i in range(preflight.MAX_TESTS + 1):
            ficheros[f"scripts/test_t{i}.py"] = "import comun\n"
        tmp = repo_falso(ficheros)
        self.addCleanup(tmp.cleanup)
        informe = preflight.preflight(["scripts/comun.py"], Path(tmp.name))
        self.assertTrue(informe["ok"])
        self.assertIn("se delega al CI", informe["python"]["aviso"])


class CableadoWorkerTest(unittest.TestCase):
    def test_worker_usa_preflight_dirigido_y_no_la_suite_completa(self):
        worker = (preflight.RAIZ / ".github" / "workflows" / "agent-worker.yml").read_text(encoding="utf-8")
        paso = worker.split("name: Validar diff y preflight", 1)[1].split("\n      - ", 1)[0]
        self.assertIn("python3 scripts/agent_preflight.py --changed", paso)
        # La suite completa lanza Godot, que el runner del worker no tiene (#1656).
        self.assertNotIn("unittest discover -s scripts -p 'test_*.py'", paso)
        self.assertNotIn("bash scripts/check_gdscript.sh", paso)
        # Se conserva el autoformato de .gd antes del --check.
        self.assertLess(paso.index('gdformat "${gd_files[@]}"'), paso.index("agent_preflight.py"))
        self.assertIn("gdtoolkit==4.3.4", paso)


if __name__ == "__main__":
    unittest.main()
