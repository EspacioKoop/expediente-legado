#!/usr/bin/env python3
"""Pruebas unitarias para configurar_proyecto en scripts/configurar_sentry.py."""

from pathlib import Path
import tempfile
import unittest

from scripts.configurar_sentry import configurar_proyecto


class TestConfigurarProyecto(unittest.TestCase):
    def setUp(self) -> None:
        self.dsn_valido = "https://key@sentry.example.org/1"
        self.release_valido = "siga98@1a2b3c"
        self.environment_valido = "alpha"
        self.dist_valida = "build.1"

        self.project_godot_base = (
            "config_version=5\n"
            "\n"
            "[application]\n"
            "\n"
            'config/name="SIGA-98"\n'
            'run/main_scene="res://escenas/inicio.tscn"\n'
        )

    def test_configurar_proyecto_dsn_valido_con_directorio_temporal(self) -> None:
        """Verifica la configuracion inicial de Sentry con un project.godot sintetico en tempdir."""
        with tempfile.TemporaryDirectory() as temp_dir:
            archivo_proyecto = Path(temp_dir) / "project.godot"
            archivo_proyecto.write_text(self.project_godot_base, encoding="utf-8")

            contenido_original = archivo_proyecto.read_text(encoding="utf-8")
            contenido_configurado = configurar_proyecto(
                contenido_original,
                dsn=self.dsn_valido,
                release=self.release_valido,
                environment=self.environment_valido,
                dist=self.dist_valida,
            )

            archivo_proyecto.write_text(contenido_configurado, encoding="utf-8")
            contenido_guardado = archivo_proyecto.read_text(encoding="utf-8")

            self.assertEqual(contenido_configurado, contenido_guardado)
            self.assertIn("[sentry]", contenido_guardado)
            self.assertIn("options/auto_init=true", contenido_guardado)
            self.assertIn(f'options/dsn="{self.dsn_valido}"', contenido_guardado)
            self.assertIn(f'options/release="{self.release_valido}"', contenido_guardado)
            self.assertIn(f'options/environment="{self.environment_valido}"', contenido_guardado)
            self.assertIn(f'options/dist="{self.dist_valida}"', contenido_guardado)
            self.assertIn("options/tracing/traces_sample_rate=0.0", contenido_guardado)

    def test_configurar_proyecto_idempotencia(self) -> None:
        """Verifica que re-ejecutar configurar_proyecto produzca exactamente el mismo resultado."""
        primera_pasada = configurar_proyecto(
            self.project_godot_base,
            dsn=self.dsn_valido,
            release=self.release_valido,
            environment=self.environment_valido,
            dist=self.dist_valida,
        )

        segunda_pasada = configurar_proyecto(
            primera_pasada,
            dsn=self.dsn_valido,
            release=self.release_valido,
            environment=self.environment_valido,
            dist=self.dist_valida,
        )

        self.assertEqual(primera_pasada, segunda_pasada)

    def test_configurar_proyecto_dsn_invalido_falla(self) -> None:
        """Verifica que DSNs invalidos (no HTTPS, sin netloc, vacios) provoquen ValueError."""
        dsns_invalidos = [
            "http://key@sentry.example.org/1",
            "ftp://key@sentry.example.org/1",
            "https://",
            "invalido",
            "",
        ]

        for dsn_invalido in dsns_invalidos:
            with self.subTest(dsn=dsn_invalido):
                with self.assertRaises(ValueError):
                    configurar_proyecto(
                        self.project_godot_base,
                        dsn=dsn_invalido,
                        release=self.release_valido,
                        environment=self.environment_valido,
                        dist=self.dist_valida,
                    )

    def test_configurar_proyecto_parametros_obligatorios_vacios_fallan(self) -> None:
        """Verifica que release o environment vacios o con solo espacios lancen ValueError."""
        with self.assertRaises(ValueError):
            configurar_proyecto(
                self.project_godot_base,
                dsn=self.dsn_valido,
                release="",
                environment=self.environment_valido,
                dist=self.dist_valida,
            )

        with self.assertRaises(ValueError):
            configurar_proyecto(
                self.project_godot_base,
                dsn=self.dsn_valido,
                release="   ",
                environment=self.environment_valido,
                dist=self.dist_valida,
            )

        with self.assertRaises(ValueError):
            configurar_proyecto(
                self.project_godot_base,
                dsn=self.dsn_valido,
                release=self.release_valido,
                environment="",
                dist=self.dist_valida,
            )

        with self.assertRaises(ValueError):
            configurar_proyecto(
                self.project_godot_base,
                dsn=self.dsn_valido,
                release=self.release_valido,
                environment="  \n\t ",
                dist=self.dist_valida,
            )

    def test_configurar_proyecto_preserva_secciones_posteriores_y_claves_personalizadas(self) -> None:
        """Verifica que se conserven claves personalizadas de [sentry] y secciones posteriores."""
        proyecto_complejo = (
            "config_version=5\n"
            "\n"
            "[application]\n"
            'config/name="SIGA-98"\n'
            "\n"
            "[sentry]\n"
            'custom_option="conservar"\n'
            'options/release="viejo_release"\n'
            "\n"
            "[rendering]\n"
            'renderer/rendering_method="forward_plus"\n'
        )

        resultado = configurar_proyecto(
            proyecto_complejo,
            dsn=self.dsn_valido,
            release=self.release_valido,
            environment=self.environment_valido,
            dist=self.dist_valida,
        )

        self.assertIn('custom_option="conservar"', resultado)
        self.assertIn("[rendering]", resultado)
        self.assertIn('renderer/rendering_method="forward_plus"', resultado)
        self.assertNotIn('options/release="viejo_release"', resultado)
        self.assertIn(f'options/release="{self.release_valido}"', resultado)

    def test_configurar_proyecto_escapa_comillas_y_barras(self) -> None:
        """Verifica el escape correcto de comillas dobles y barras invertidas en las cadenas literalizadas."""
        resultado = configurar_proyecto(
            self.project_godot_base,
            dsn=self.dsn_valido,
            release='rel"ease\\v1',
            environment='env"1\\test',
            dist='dist"1\\a',
        )

        self.assertIn(r'options/release="rel\"ease\\v1"', resultado)
        self.assertIn(r'options/environment="env\"1\\test"', resultado)
        self.assertIn(r'options/dist="dist\"1\\a"', resultado)


if __name__ == "__main__":
    unittest.main()
