"""Mobiliario CC0 de casa (#227): procedencia, GLB autocontenidos y montaje real."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
CARPETA = ROOT / "godot/assets/modelos/household_goods"
FUENTE = "https://mastjie.itch.io/low-poly-household-goods"
MODELOS = {
    "2_seat_sofa_01", "chair_01", "coffee_table_01", "cupboard_01", "dine_table_01",
    "kettle_01", "microwave_01", "stove_01", "table_lamp_01", "toaster_01",
    "tv_cabinet_01", "wardrobe_01", "washing_machine_01",
}
# Siluetas que no pertenecen a una casa de 1998.
FUERA_DE_EPOCA = {"laptop_01", "tv_01", "air_conditioner_01", "computer_01", "fridge_01"}


class HouseholdGoodsCc0Test(unittest.TestCase):
    def test_seleccion_acotada_y_de_epoca(self):
        presentes = {p.stem for p in CARPETA.glob("*.glb")}
        self.assertEqual(presentes, MODELOS)
        self.assertFalse(presentes & FUERA_DE_EPOCA)

    def test_procedencia_y_glb_autocontenidos(self):
        fichas = json.loads((ROOT / "godot/assets/procedencia.json").read_text())["assets"]
        por_ruta = {f["ruta"]: f for f in fichas}
        for ruta in sorted(CARPETA.glob("*")):
            if ruta.suffix == ".import":
                continue
            with self.subTest(fichero=ruta.name):
                ficha = por_ruta["modelos/household_goods/" + ruta.name]
                datos = ruta.read_bytes()
                self.assertEqual(ficha["sha256"], hashlib.sha256(datos).hexdigest())
                self.assertEqual(ficha["licencia"], "CC0-1.0")
                self.assertEqual(ficha["fuente"], FUENTE)
                if ruta.suffix == ".glb":
                    largo = int.from_bytes(datos[12:16], "little")
                    gltf = json.loads(datos[20:20 + largo])
                    self.assertTrue(all("uri" not in b for b in gltf["buffers"]))
                    self.assertTrue(all("bufferView" in i for i in gltf["images"]))

    def test_utileria_delega_los_assets_en_el_modulo_cc0(self):
        utileria = (ROOT / "godot/guion/casa_utileria.gd").read_text(encoding="utf-8")
        self.assertIn("CasaHogarCC0.montar(raiz)", utileria)

    def test_montaje_real_en_casa(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="casa-hogar-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [motor, "--headless", "--language", "es", "--path", str(ROOT / "godot")]
            for argumentos, minimo in [
                (["--editor", "--import", "--quit"], None),
                (["--script", "res://pruebas/pruebas_casa_hogar_cc0.gd"], 150),
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
