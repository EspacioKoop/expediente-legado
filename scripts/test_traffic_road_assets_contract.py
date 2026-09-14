from pathlib import Path
import unittest
import hashlib
import json
import os
import struct
import subprocess
import tempfile

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "assets" / "traffic-road-assets.md"
GITATTRIBUTES = ROOT / ".gitattributes"


class TestTrafficRoadAssetsContract(unittest.TestCase):
    def test_fuente_y_licencia_quedan_fijadas(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("https://milkandbanana.itch.io/traffic-road-assets", texto)
        self.assertIn("CC0 1.0 Universal", texto)
        self.assertIn("jamesdev", texto)

    def test_catalogo_no_inventa_contenido_que_la_fuente_no_publica(self):
        texto = DOC.read_text(encoding="utf-8")
        for familia in (
            "traffic cones",
            "crush barriers",
            "manhole covers",
            "roadblocks",
            "streetlights",
            "water hydrants",
        ):
            self.assertIn(familia, texto)
        self.assertIn("no anuncia", texto)
        self.assertIn("señales de tráfico", texto)
        self.assertIn("vehículos", texto)

    def test_seleccion_minima_esta_acotada_y_es_no_interactiva(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("No importar el pack completo", texto)
        self.assertIn("Manhole cover", texto)
        self.assertIn("Concrete roadblock", texto)
        self.assertIn("Traffic cone", texto)
        self.assertIn("Streetlight", texto)
        self.assertIn("sin `RigidBody3D`, IA ni interacción", texto)

    def test_trafico_movil_se_delega_a_coches_del_issue_230(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("#230", texto)
        self.assertIn("ruta simple", texto)
        self.assertIn("sin navegación, avoidance ni física de vehículo", texto)

    def test_formatos_binarios_estan_cubiertos_por_lfs(self):
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.glb   filter=lfs", atributos)
        self.assertIn("*.fbx   filter=lfs", atributos)
        self.assertIn("*.png   filter=lfs", atributos)

    def test_pr_binario_exige_procedencia_y_sha(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("godot/assets/procedencia.json", texto)
        self.assertIn("sha256", texto)
        self.assertIn("Git LFS real", texto)


class TestTrafficRoadAssetsRuntime(unittest.TestCase):
    def test_lote_original_autocontenido_con_hashes(self):
        carpeta = ROOT / "godot/assets/modelos/traffic_road"
        fichas = json.loads((ROOT / "godot/assets/procedencia.json").read_text())["assets"]
        por_ruta = {f["ruta"]: f for f in fichas}
        modelos = sorted(carpeta.glob("*.glb"))
        self.assertEqual([p.stem for p in modelos], ["Manhole_Cover", "Road_Block", "Traffic_Cone"])
        for ruta in modelos:
            with self.subTest(modelo=ruta.name):
                datos = ruta.read_bytes()
                self.assertEqual(datos[:4], b"glTF")
                self.assertEqual(struct.unpack_from("<I", datos, 8)[0], len(datos))
                largo = struct.unpack_from("<I", datos, 12)[0]
                gltf = json.loads(datos[20:20 + largo])
                self.assertTrue(gltf.get("images"))
                self.assertTrue(all("bufferView" in im for im in gltf["images"]))
                self.assertTrue(all("uri" not in b for b in gltf["buffers"]))
                ficha = por_ruta["modelos/traffic_road/" + ruta.name]
                self.assertEqual(ficha["sha256"], hashlib.sha256(datos).hexdigest())
                self.assertEqual(ficha["licencia"], "CC0-1.0")
                self.assertIn("MilkAndBanana", ficha["autor"])

    def test_montaje_y_transiciones_en_escena_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="trafico-vial-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [motor, "--headless", "--language", "es", "--path", str(ROOT / "godot")]
            for argumentos, minimo in [
                (["--editor", "--import", "--quit"], None),
                (["--script", "res://pruebas/pruebas_trafico_vial_cc0.gd"], 50),
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
