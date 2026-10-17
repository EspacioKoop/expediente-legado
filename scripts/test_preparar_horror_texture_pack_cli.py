from __future__ import annotations

import argparse
import importlib.util
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

RAIZ = Path(__file__).resolve().parents[1]
SCRIPT = RAIZ / "scripts" / "preparar_horror_texture_pack.py"

spec = importlib.util.spec_from_file_location("preparar_horror_texture_pack", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


class TestPrepararHorrorTexturePackCLI(unittest.TestCase):
    """Pruebas para las funciones CLI de preparar_horror_texture_pack.py:

    extraer_rar y construir_parser.
    """

    def test_extraer_rar_herramienta_ausente_lanza_value_error(self) -> None:
        with patch("shutil.which", return_value=None):
            with self.assertRaisesRegex(ValueError, "no hay extractor RAR disponible"):
                modulo.extraer_rar(Path("entrada.rar"), Path("destino"))

    def test_extraer_rar_fallo_extraccion_lanza_called_process_error(self) -> None:
        with (
            patch("shutil.which", side_effect=lambda cmd: "/usr/bin/7z" if cmd == "7z" else None),
            patch(
                "subprocess.run",
                side_effect=subprocess.CalledProcessError(1, ["7z"], stderr=b"Error"),
            ),
        ):
            with self.assertRaises(subprocess.CalledProcessError):
                modulo.extraer_rar(Path("entrada.rar"), Path("destino"))

    def test_extraer_rar_comando_por_herramienta(self) -> None:
        casos = [
            ("7z", ["7z", "x", "-y", "entrada.rar", "-odestino"]),
            ("unrar", ["unrar", "x", "-o+", "entrada.rar", "destino/"]),
            ("unar", ["unar", "-f", "-o", "destino", "entrada.rar"]),
            ("bsdtar", ["bsdtar", "-xf", "entrada.rar", "-C", "destino"]),
        ]
        origen = Path("entrada.rar")
        destino = Path("destino")

        for herramienta, comando_esperado in casos:
            with self.subTest(herramienta=herramienta):
                with (
                    patch(
                        "shutil.which",
                        side_effect=lambda cmd, h=herramienta: f"/usr/bin/{h}" if cmd == h else None,
                    ),
                    patch("subprocess.run") as mock_run,
                ):
                    modulo.extraer_rar(origen, destino)
                    mock_run.assert_called_once_with(
                        comando_esperado,
                        check=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                    )

    def test_construir_parser_argumentos_minimos_y_valores_por_defecto(self) -> None:
        parser = modulo.construir_parser()
        self.assertIsInstance(parser, argparse.ArgumentParser)

        args = parser.parse_args(["paquete.rar"])
        self.assertEqual(args.origen, Path("paquete.rar"))
        self.assertEqual(args.resolucion, 128)
        self.assertEqual(args.destino_assets, Path("godot/assets"))
        self.assertEqual(args.manifiesto, Path("docs/assets/horror-texture-pack.manifest.json"))
        self.assertIsNone(args.perfiles)
        self.assertFalse(args.todos)
        self.assertFalse(args.permitir_gore)

    def test_construir_parser_opciones_personalizadas(self) -> None:
        parser = modulo.construir_parser()
        args = parser.parse_args(
            [
                "paquete.rar",
                "--resolucion",
                "256",
                "--destino-assets",
                "mi_godot/assets",
                "--manifiesto",
                "mi_manifiesto.json",
                "--perfil",
                "sueno_escuela",
                "--perfil",
                "sutil",
                "--todos",
                "--permitir-gore",
            ]
        )
        self.assertEqual(args.origen, Path("paquete.rar"))
        self.assertEqual(args.resolucion, 256)
        self.assertEqual(args.destino_assets, Path("mi_godot/assets"))
        self.assertEqual(args.manifiesto, Path("mi_manifiesto.json"))
        self.assertEqual(args.perfiles, ["sueno_escuela", "sutil"])
        self.assertTrue(args.todos)
        self.assertTrue(args.permitir_gore)


if __name__ == "__main__":
    unittest.main()
