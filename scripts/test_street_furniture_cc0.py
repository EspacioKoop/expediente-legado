"""Basura urbana y aparatos de aire CC0 en el trayecto (#222)."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
CARPETA = ROOT / "godot/assets/modelos/street_furniture"
FUENTE = "https://kkryy.itch.io/streetfurniture"


class StreetFurnitureCc0Test(unittest.TestCase):
    def test_seleccion_acotada(self):
        self.assertEqual(
            sorted(p.stem for p in CARPETA.glob("*.glb")),
            ["Cardboard", "Conditioner", "GarbageBag", "TrashCan"],
        )
        self.assertFalse(list(CARPETA.glob("*.fbx")), "los FBX de origen no se versionan")

    def test_procedencia_y_glb_autocontenidos(self):
        fichas = json.loads((ROOT / "godot/assets/procedencia.json").read_text())["assets"]
        por_ruta = {f["ruta"]: f for f in fichas}
        for ruta in sorted(CARPETA.glob("*")):
            if ruta.suffix == ".import":
                continue
            with self.subTest(fichero=ruta.name):
                ficha = por_ruta["modelos/street_furniture/" + ruta.name]
                datos = ruta.read_bytes()
                self.assertEqual(ficha["sha256"], hashlib.sha256(datos).hexdigest())
                self.assertEqual((ficha["autor"], ficha["licencia"], ficha["fuente"]), ("Kkryy", "CC0-1.0", FUENTE))
                if ruta.suffix == ".glb":
                    largo = int.from_bytes(datos[12:16], "little")
                    gltf = json.loads(datos[20:20 + largo])
                    self.assertEqual(len(gltf["images"]), 1)
                    self.assertTrue(all("uri" not in b for b in gltf["buffers"]))

    def test_documenta_seleccion_y_descartes(self):
        texto = (ROOT / "docs/assets/street-furniture.md").read_text(encoding="utf-8")
        for termino in ("CC0 1.0 Universal", "Kkryy", FUENTE, "sha256", "Bottles", "Git LFS"):
            self.assertIn(termino, texto)

    def test_montaje_y_transiciones_en_escena_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="mobiliario-urbano-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [motor, "--headless", "--language", "es", "--path", str(ROOT / "godot")]
            for argumentos, minimo in [
                (["--editor", "--import", "--quit"], None),
                (["--script", "res://pruebas/pruebas_mobiliario_urbano_cc0.gd"], 120),
            ]:
                resultado = subprocess.run(
                    base + argumentos, env=entorno, text=True, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, timeout=180, check=False,
                )
                try:
                    validar(resultado.stdout, resultado.returncode, minimo, minimo is None)
                except ValueError as error:
                    self.fail(f"{error}\n{resultado.stdout}")


if __name__ == "__main__":
    unittest.main()
