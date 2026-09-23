from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
GODOT = RAIZ / "godot"
HORROR = GODOT / "guion" / "horror_texturas.gd"
TEXTURAS = GODOT / "guion" / "textura_procedural.gd"
DIA_SUENO = GODOT / "guion" / "dia_sueno_app.gd"
SUENO = GODOT / "guion" / "sueno.gd"
PROCEDENCIA = GODOT / "assets" / "procedencia.json"
PAQUETE_128_SHA256 = "1fee483ce0253e64096442a2c16833ec9da90bdfa2836e5d54a061f293abf6fb"


class HorrorTexturasContractTest(unittest.TestCase):
    def test_pack_vive_fuera_del_material_generico(self) -> None:
        horror = HORROR.read_text(encoding="utf-8")
        texturas = TEXTURAS.read_text(encoding="utf-8")
        self.assertIn("class_name HorrorTexturas", horror)
        self.assertNotIn("HORROR_PERFILES_SUENO", texturas)
        self.assertNotIn("aplicar_horror_sueno", texturas)

    def test_no_hay_sangre_en_perfiles_automaticos(self) -> None:
        horror = HORROR.read_text(encoding="utf-8")
        for indice in range(1, 6):
            self.assertNotIn(f'Horror_Stain_{indice:02d}"', horror)

    def test_integracion_ocurre_despues_de_identidad_onirica(self) -> None:
        dia = DIA_SUENO.read_text(encoding="utf-8")
        sueno = SUENO.read_text(encoding="utf-8")
        self.assertIn("HorrorTexturas.nivel_para_noche", dia)
        self.assertIn("HorrorTexturas.aplicar", dia)
        self.assertLess(dia.index("SuenoEscuela.adaptar_espacio"), dia.index("HorrorTexturas.aplicar"))
        self.assertNotIn("TexturaProcedural.aplicar_horror_sueno", sueno)

    def test_lote_lfs_cubre_exactamente_los_perfiles(self) -> None:
        # Se lee el PNG como puntero LFS desde el índice de git: así la prueba
        # vale también en un checkout sin objetos descargados.
        horror = HORROR.read_text(encoding="utf-8")
        ids = set(re.findall(r'"((?:Brick|Floor|Metal|Misc|Stains|Stone|Wall)/Horror_\w+)"', horror))
        self.assertTrue(ids)
        fichas = {
            ficha["ruta"]: ficha
            for ficha in json.loads(PROCEDENCIA.read_text(encoding="utf-8"))["assets"]
        }
        lote = GODOT / "assets" / "texturas" / "horror_sbs" / "128x128"
        instalados = {
            ruta.relative_to(lote).as_posix().removesuffix("-128x128.png")
            for ruta in lote.rglob("*.png")
        }
        self.assertEqual(instalados, ids, "el lote debe ser exactamente lo que consumen los perfiles")
        for identificador in sorted(ids):
            with self.subTest(identificador=identificador):
                self.assertNotRegex(identificador, r"Stain_0[1-5]$")
                rel = f"texturas/horror_sbs/128x128/{identificador}-128x128.png"
                ficha = fichas.get(rel)
                self.assertIsNotNone(ficha, f"falta la procedencia de {rel}")
                self.assertEqual(ficha["licencia"], "CC0-1.0")
                self.assertEqual(ficha["paquete_sha256"], PAQUETE_128_SHA256)
                puntero = subprocess.run(
                    ["git", "-C", str(RAIZ), "show", f":godot/assets/{rel}"],
                    stdout=subprocess.PIPE,
                    check=False,
                ).stdout.decode("utf-8", "replace")
                if puntero.startswith("version https://git-lfs"):
                    self.assertIn(f"oid sha256:{ficha['sha256']}", puntero)

    def test_smoke_godot(self) -> None:
        motor = shutil.which(os.environ.get("GODOT_BIN", "godot4"))
        if motor is None:
            self.skipTest("Godot no está instalado en este entorno")
        with tempfile.TemporaryDirectory(prefix="horror-texturas-") as temporal:
            entorno = os.environ.copy()
            for variable, carpeta in (
                ("XDG_DATA_HOME", "datos"),
                ("XDG_CONFIG_HOME", "config"),
                ("XDG_CACHE_HOME", "cache"),
            ):
                entorno[variable] = str(Path(temporal) / carpeta)
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--path",
                    str(GODOT),
                    "--script",
                    "res://pruebas/horror_texturas_smoke.gd",
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=30,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("horror_texturas_smoke: 0 fallos", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
