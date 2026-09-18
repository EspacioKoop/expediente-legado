from pathlib import Path
import hashlib
import json
import os
import struct
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "assets" / "psx-style-cars.md"
GITATTRIBUTES = ROOT / ".gitattributes"
RUNTIME = ROOT / "godot" / "guion" / "coches_psx_cc0.gd"


class TestPsxStyleCarsContract(unittest.TestCase):
    def test_fuente_y_licencia_quedan_fijadas(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("https://ggbot.itch.io/psx-style-cars", texto)
        self.assertIn("CC0 1.0 Universal", texto)
        self.assertIn("GGBotNet", texto)

    def test_seleccion_minima_no_importa_el_pack_completo(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("Car 01", texto)
        self.assertIn("Car 03", texto)
        self.assertIn("Car 04", texto)
        self.assertIn("No importar el pack completo", texto)

    def test_escala_se_normaliza_por_modelo(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("unidad de escala entre coches no es correcta", texto)
        self.assertIn("normalizarse individualmente", texto)

    def test_binarios_relevantes_estan_cubiertos_por_lfs(self):
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.glb   filter=lfs", atributos)
        self.assertIn("*.blend filter=lfs", atributos)
        self.assertIn("*.png   filter=lfs", atributos)

    def test_pr_binario_exige_procedencia_y_sha(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("godot/assets/procedencia.json", texto)
        self.assertIn("sha256", texto)
        self.assertIn("Git LFS real", texto)

    def test_trafico_lejano_es_barato_y_no_jugable(self):
        texto = DOC.read_text(encoding="utf-8")
        runtime = RUNTIME.read_text(encoding="utf-8")
        self.assertIn("Segundo corte — tráfico lejano", texto)
        self.assertIn("sin colisión", texto)
        self.assertIn("TRAFICO_FONDO", runtime)
        self.assertIn("create_tween().set_loops()", runtime)
        self.assertNotIn("VehicleBody3D.new", runtime)
        self.assertNotIn("NavigationAgent3D.new", runtime)


class TestPsxStyleCarsRuntime(unittest.TestCase):
    def test_lote_autocontenido_con_hashes(self):
        carpeta = ROOT / "godot/assets/modelos/psx_cars"
        fichas = json.loads((ROOT / "godot/assets/procedencia.json").read_text())["assets"]
        por_ruta = {f["ruta"]: f for f in fichas}
        modelos = sorted(carpeta.glob("*.glb"))
        self.assertEqual([p.stem for p in modelos], ["Car01", "Car03", "Car04"])
        triangulos = {"Car01": 438, "Car03": 448, "Car04": 476}
        for ruta in modelos:
            with self.subTest(modelo=ruta.name):
                datos = ruta.read_bytes()
                self.assertEqual(datos[:4], b"glTF")
                self.assertEqual(struct.unpack_from("<I", datos, 8)[0], len(datos))
                largo = struct.unpack_from("<I", datos, 12)[0]
                gltf = json.loads(datos[20:20 + largo])
                self.assertEqual(len(gltf["images"]), 1)
                self.assertTrue(all("bufferView" in im for im in gltf["images"]))
                self.assertTrue(all("uri" not in b for b in gltf["buffers"]))
                indices = gltf["meshes"][0]["primitives"][0]["indices"]
                self.assertEqual(gltf["accessors"][indices]["count"] // 3, triangulos[ruta.stem])
                ficha = por_ruta["modelos/psx_cars/" + ruta.name]
                self.assertEqual(ficha["sha256"], hashlib.sha256(datos).hexdigest())
                self.assertEqual(ficha["licencia"], "CC0-1.0")
                self.assertEqual(ficha["autor"], "GGBotNet")
                self.assertEqual(ficha["fuente"], "https://ggbot.itch.io/psx-style-cars")

    def test_montaje_y_transiciones_en_escena_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="coches-psx-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [motor, "--headless", "--language", "es", "--path", str(ROOT / "godot")]
            for argumentos, minimo in [
                (["--editor", "--import", "--quit"], None),
                (["--script", "res://pruebas/pruebas_coches_psx_cc0.gd"], 65),
            ]:
                resultado = subprocess.run(
                    base + argumentos, env=entorno, text=True, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, timeout=120, check=False,
                )
                try:
                    validar(resultado.stdout, resultado.returncode, minimo, minimo is None)
                except ValueError as error:
                    self.fail(f"{error}\n{resultado.stdout}")


if __name__ == "__main__":
    unittest.main()
