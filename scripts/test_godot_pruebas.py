from pathlib import Path
import unittest
from unittest import mock

from scripts import godot_pruebas


class ExigirExtensionTest(unittest.TestCase):
    def tearDown(self):
        godot_pruebas.importar_proyecto.cache_clear()

    def test_con_la_biblioteca_presente_no_corta(self):
        with mock.patch.object(Path, "exists", lambda self: True):
            godot_pruebas.exigir_extension()

    def test_sin_biblioteca_salta_con_la_orden_exacta(self):
        with mock.patch.object(Path, "exists", lambda self: False), mock.patch.object(
            godot_pruebas, "EXIGIR_EXTENSION", False
        ):
            with self.assertRaises(unittest.SkipTest) as ctx:
                godot_pruebas.exigir_extension()
        self.assertIn(godot_pruebas.PREPARAR, str(ctx.exception))

    def test_sin_biblioteca_en_ci_es_fallo_real(self):
        with mock.patch.object(Path, "exists", lambda self: False), mock.patch.object(
            godot_pruebas, "EXIGIR_EXTENSION", True
        ):
            with self.assertRaises(AssertionError) as ctx:
                godot_pruebas.exigir_extension()
        self.assertIn(godot_pruebas.PREPARAR, str(ctx.exception))


class ImportarProyectoTest(unittest.TestCase):
    def tearDown(self):
        godot_pruebas.importar_proyecto.cache_clear()

    def test_solo_importa_una_vez_por_proceso(self):
        llamadas = []

        def falso_run(orden, **kwargs):
            llamadas.append(orden)
            return mock.Mock(stdout="", returncode=0)

        godot_pruebas.importar_proyecto.cache_clear()
        with mock.patch.object(godot_pruebas.subprocess, "run", falso_run), mock.patch.object(
            godot_pruebas, "exigir_extension", lambda: None
        ), mock.patch.object(godot_pruebas, "validar", lambda *a, **k: None):
            godot_pruebas.importar_proyecto()
            godot_pruebas.importar_proyecto()
            godot_pruebas.importar_proyecto()

        self.assertEqual(1, len(llamadas))
        self.assertIn("--import", llamadas[0])


if __name__ == "__main__":
    unittest.main()
