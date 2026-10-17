from __future__ import annotations

import json
import sys
import subprocess
import tempfile
import unittest
from pathlib import Path

from scripts.roms_propias_ausentes import ausentes, RAIZ

SCRIPT_PATH = Path(__file__).resolve().parent / "roms_propias_ausentes.py"


class TestRomsPropiasAusentes(unittest.TestCase):
    def crear_entorno_sintetico(
        self, tmp_dir: str, roms_json_data: dict, archivos_crear: list[str]
    ) -> Path:
        raiz = Path(tmp_dir)
        indice_dir = raiz / "godot" / "datos"
        indice_dir.mkdir(parents=True, exist_ok=True)
        (indice_dir / "roms_propias.json").write_text(
            json.dumps(roms_json_data, ensure_ascii=False), encoding="utf-8"
        )

        for rel_path in archivos_crear:
            file_path = raiz / "godot" / rel_path
            file_path.parent.mkdir(parents=True, exist_ok=True)
            file_path.write_bytes(b"GBC_DUMMY")

        return raiz

    def test_ausentes_devuelve_lista_vacia_cuando_todas_las_roms_existen(self) -> None:
        datos = {
            "roms": [
                {
                    "id": "juego_1",
                    "estado": "jugable",
                    "rom": "res://roms/juego_1.gbc",
                },
                {
                    "id": "juego_2",
                    "estado": "jugable",
                    "rom": "res://roms/juego_2.gbc",
                },
            ]
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            raiz = self.crear_entorno_sintetico(
                tmp_dir, datos, ["roms/juego_1.gbc", "roms/juego_2.gbc"]
            )
            resultado = ausentes(raiz)
            self.assertEqual(resultado, [])

    def test_ausentes_detecta_roms_jugables_faltantes(self) -> None:
        datos = {
            "roms": [
                {
                    "id": "juego_1",
                    "estado": "jugable",
                    "rom": "res://roms/juego_1.gbc",
                },
                {
                    "id": "juego_2",
                    "estado": "jugable",
                    "rom": "res://roms/juego_2.gbc",
                },
                {
                    "id": "juego_3",
                    "estado": "jugable",
                    "rom": "res://roms/juego_3.gbc",
                },
            ]
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            raiz = self.crear_entorno_sintetico(tmp_dir, datos, ["roms/juego_1.gbc"])
            resultado = ausentes(raiz)
            self.assertEqual(resultado, ["juego_2", "juego_3"])

    def test_ausentes_ignora_roms_no_jugables_o_sin_prefijo_res(self) -> None:
        datos = {
            "roms": [
                {
                    "id": "juego_en_proyecto",
                    "estado": "en_proyecto",
                    "rom": "res://roms/juego_en_proyecto.gbc",
                },
                {
                    "id": "juego_sin_res",
                    "estado": "jugable",
                    "rom": "roms/juego_sin_res.gbc",
                },
                {
                    "id": "juego_jugable_faltante",
                    "estado": "jugable",
                    "rom": "res://roms/juego_jugable_faltante.gbc",
                },
            ]
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            raiz = self.crear_entorno_sintetico(tmp_dir, datos, [])
            resultado = ausentes(raiz)
            self.assertEqual(resultado, ["juego_jugable_faltante"])

    def test_ausentes_parametro_por_defecto_usa_raiz(self) -> None:
        resultado = ausentes()
        self.assertIsInstance(resultado, list)

    def test_cli_main_con_argumento_de_ruta(self) -> None:
        datos = {
            "roms": [
                {
                    "id": "rom_cli_1",
                    "estado": "jugable",
                    "rom": "res://roms/rom_cli_1.gbc",
                },
                {
                    "id": "rom_cli_2",
                    "estado": "jugable",
                    "rom": "res://roms/rom_cli_2.gbc",
                },
            ]
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            raiz = self.crear_entorno_sintetico(tmp_dir, datos, ["roms/rom_cli_1.gbc"])
            proceso = subprocess.run(
                [sys.executable, str(SCRIPT_PATH), str(raiz)],
                capture_output=True,
                text=True,
                check=True,
            )
            self.assertEqual(proceso.stdout.strip(), "rom_cli_2")

    def test_cli_main_sin_argumentos(self) -> None:
        proceso = subprocess.run(
            [sys.executable, str(SCRIPT_PATH)],
            capture_output=True,
            text=True,
            check=True,
        )
        # Should execute without errors and print output
        self.assertEqual(proceso.returncode, 0)


if __name__ == "__main__":
    unittest.main()
