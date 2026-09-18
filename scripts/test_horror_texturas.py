from __future__ import annotations

import os
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
