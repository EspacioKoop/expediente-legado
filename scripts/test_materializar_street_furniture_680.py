import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "materializar_street_furniture_680",
    SCRIPTS / "materializar_street_furniture_680.py",
)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def glb2(documento: dict, binario: bytes = b"\x00\x00\x00\x00") -> bytes:
    json_bytes = json.dumps(documento, separators=(",", ":")).encode("utf-8")
    json_bytes += b" " * ((4 - len(json_bytes) % 4) % 4)
    binario += b"\x00" * ((4 - len(binario) % 4) % 4)
    total = 12 + 8 + len(json_bytes) + 8 + len(binario)
    return (
        b"glTF"
        + struct.pack("<II", 2, total)
        + struct.pack("<II", len(json_bytes), 0x4E4F534A)
        + json_bytes
        + struct.pack("<II", len(binario), 0x004E4942)
        + binario
    )


class MaterializarStreetFurniture680Test(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.raiz = Path(self.tmp.name)
        self.extraido = self.raiz / "extraido"
        self.preparado = self.raiz / "preparado"
        self.extraido.mkdir()
        self.preparado.mkdir()
        for asset in mod.ASSETS.values():
            fbx = self.extraido / asset["fbx"]
            png = self.extraido / asset["png_fuente"]
            fbx.parent.mkdir(parents=True, exist_ok=True)
            fbx.write_bytes(b"fbx-fixture")
            png.write_bytes(b"\x89PNG\r\n\x1a\nsource")
            (self.preparado / asset["glb"]).write_bytes(
                glb2(
                    {
                        "asset": {"version": "2.0"},
                        "buffers": [{"byteLength": 4}],
                        "images": [{"bufferView": 0, "mimeType": "image/png"}],
                    }
                )
            )
            (self.preparado / asset["png"]).write_bytes(
                b"\x89PNG\r\n\x1a\nprepared"
            )

    def tearDown(self):
        self.tmp.cleanup()

    def test_seleccion_acotada_ordenada_e_idempotente(self):
        seleccion = mod.seleccionar(["flashlight", "crowbar", "flashlight"])
        self.assertEqual([asset_id for asset_id, _ in seleccion], ["flashlight", "crowbar"])
        with self.assertRaisesRegex(mod.MaterializacionError, "desconocidos"):
            mod.seleccionar(["hammer"])

    def test_fuentes_exigen_fbx_y_png_del_pack(self):
        seleccion = mod.seleccionar(["crowbar"])
        mod.validar_fuentes_extraidas(self.extraido, seleccion)
        (self.extraido / mod.ASSETS["crowbar"]["png_fuente"]).unlink()
        with self.assertRaisesRegex(mod.MaterializacionError, "Falta fuente esperada"):
            mod.validar_fuentes_extraidas(self.extraido, seleccion)

    def test_glb2_debe_ser_autocontenido(self):
        bueno = self.preparado / mod.ASSETS["crowbar"]["glb"]
        mod.validar_glb_autocontenido(bueno)

        externo = self.raiz / "externo.glb"
        externo.write_bytes(
            glb2(
                {
                    "asset": {"version": "2.0"},
                    "buffers": [{"byteLength": 4, "uri": "malla.bin"}],
                }
            )
        )
        with self.assertRaisesRegex(mod.MaterializacionError, "buffer externo"):
            mod.validar_glb_autocontenido(externo)

        version1 = bytearray(bueno.read_bytes())
        struct.pack_into("<I", version1, 4, 1)
        antiguo = self.raiz / "antiguo.glb"
        antiguo.write_bytes(version1)
        with self.assertRaisesRegex(mod.MaterializacionError, "debe ser glTF 2"):
            mod.validar_glb_autocontenido(antiguo)

    def test_preparados_fijan_hash_y_tamano_reales(self):
        seleccion = mod.seleccionar(["crowbar"])
        preparados = mod.validar_preparados(self.preparado, seleccion)
        info = preparados["crowbar"]
        self.assertEqual(
            info["glb_sha256"],
            hashlib.sha256((self.preparado / "Crowbar.glb").read_bytes()).hexdigest(),
        )
        self.assertGreater(info["glb_bytes"], 20)
        self.assertRegex(info["png_sha256"], r"^[0-9a-f]{64}$")

    def test_aplicar_exige_zip_original_verificado(self):
        with self.assertRaisesRegex(mod.MaterializacionError, "--aplicar exige --archivo"):
            mod.validar_archivo_fuente(None, obligatorio=True)

        archivo = self.raiz / "Street Furniture.zip"
        archivo.write_bytes(b"zip-incorrecto")
        with self.assertRaisesRegex(mod.MaterializacionError, "SHA-256"):
            mod.validar_archivo_fuente(archivo, obligatorio=True)

    def test_procedencia_incluye_origen_y_hash_del_pack(self):
        seleccion = mod.seleccionar(["crowbar"])
        preparados = mod.validar_preparados(self.preparado, seleccion)
        entradas = mod.entradas_procedencia(seleccion, preparados)
        self.assertEqual(len(entradas), 2)
        glb = entradas[0]
        png = entradas[1]
        self.assertEqual(glb["ruta"], "modelos/street_furniture/Crowbar.glb")
        self.assertIn("Crowbar/Crowbar.fbx", glb["archivo_origen"])
        self.assertEqual(glb["paquete_sha256"], mod.ARCHIVO_SHA256)
        self.assertEqual(png["archivo_origen"], "Crowbar/Crowbar.png")
        self.assertEqual((glb["autor"], glb["licencia"]), ("Kkryy", "CC0-1.0"))

    def test_fusion_procedencia_es_idempotente_y_no_pisa(self):
        seleccion = mod.seleccionar(["crowbar"])
        preparados = mod.validar_preparados(self.preparado, seleccion)
        nuevas = mod.entradas_procedencia(seleccion, preparados)
        base = {"_regla": "fixture", "assets": []}

        primera, añadidas = mod.fusionar_procedencia(copy.deepcopy(base), nuevas)
        self.assertEqual(len(añadidas), 2)
        segunda, añadidas_segunda = mod.fusionar_procedencia(
            copy.deepcopy(primera), nuevas
        )
        self.assertEqual(añadidas_segunda, [])
        self.assertEqual(segunda, primera)

        conflicto = copy.deepcopy(primera)
        conflicto["assets"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(mod.MaterializacionError, "distinto"):
            mod.fusionar_procedencia(conflicto, nuevas)

    def test_puntero_lfs_exige_oid_y_tamano(self):
        sha = "1" * 64
        bueno = (
            "version https://git-lfs.github.com/spec/v1\n"
            f"oid sha256:{sha}\n"
            "size 123\n"
        ).encode("ascii")
        self.assertTrue(mod.puntero_lfs_correcto(bueno, sha, 123))
        self.assertFalse(mod.puntero_lfs_correcto(bueno, sha, 124))
        self.assertFalse(mod.puntero_lfs_correcto(b"GLB-binario", sha, 123))


if __name__ == "__main__":
    unittest.main()
