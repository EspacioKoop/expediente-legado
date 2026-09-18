import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

MODULO_RUTA = Path(__file__).with_name("preparar_school_classrooms_styloo.py")
SPEC = importlib.util.spec_from_file_location("preparar_school_classrooms_styloo", MODULO_RUTA)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
import sys
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class PrepararSchoolClassroomsStylooTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.raiz = Path(self.tmp.name)
        self.readme = "pack/read me .txt"
        self.assets = {
            "desk": ("pack/principal/desk.glb", b"desk-real"),
            "telephone": ("pack/principal/telephone.glb", b"telefono-real"),
            "locker": ("pack/classroom/locker.glb", b"locker-real"),
        }
        self.zip = self.raiz / "pack.zip"
        self._escribir_zip(self.zip)
        hash_zip = mod.sha256_fichero(self.zip)
        manifest = {
            "fuente": "https://example.invalid/styloo",
            "autor": "styloo",
            "licencia": "CC0-1.0",
            "archivo_sha256": hash_zip,
            "readme_interno": self.readme,
            "lotes": {
                "administrativo": ["desk", "telephone"],
                "escuela_sueno": ["locker"],
            },
            "assets": [],
        }
        for asset_id, (miembro, datos) in self.assets.items():
            manifest["assets"].append(
                {
                    "id": asset_id,
                    "titulo": asset_id,
                    "miembro_zip": miembro,
                    "destino_sugerido": f"{asset_id}.glb",
                    "bytes": len(datos),
                    "sha256": hashlib.sha256(datos).hexdigest(),
                }
            )
        self.manifest = self.raiz / "manifest.json"
        self.manifest.write_text(json.dumps(manifest), encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def _escribir_zip(self, ruta, *, comentario=b""):
        with zipfile.ZipFile(ruta, "w") as archivo:
            archivo.writestr(self.readme, "GLB works fine")
            for miembro, datos in self.assets.values():
                archivo.writestr(miembro, datos)
            archivo.writestr("pack/classroom/demoscene.glb", b"NO IMPORTAR")
            archivo.comment = comentario

    def test_por_defecto_extrae_solo_lote_administrativo(self):
        manifest = mod.cargar_manifiesto(self.manifest)
        seleccion = mod.seleccionar_assets(manifest, ["administrativo"])
        extraidos = mod.validar_zip(self.zip, manifest, seleccion)
        salida = self.raiz / "staging"
        staging = mod.preparar_staging(salida, manifest, seleccion, extraidos)
        self.assertEqual(staging["cantidad"], 2)
        self.assertTrue((salida / "desk.glb").exists())
        self.assertTrue((salida / "telephone.glb").exists())
        self.assertFalse((salida / "locker.glb").exists())
        self.assertFalse((salida / "demoscene.glb").exists())

    def test_lote_escolar_permanece_separado(self):
        manifest = mod.cargar_manifiesto(self.manifest)
        seleccion = mod.seleccionar_assets(manifest, ["escuela_sueno"])
        self.assertEqual([a["id"] for a in seleccion], ["locker"])

    def test_rechaza_hash_de_miembro_distinto(self):
        manifest = mod.cargar_manifiesto(self.manifest)
        manifest["assets"][0]["sha256"] = "0" * 64
        seleccion = mod.seleccionar_assets(manifest, ["administrativo"])
        with self.assertRaisesRegex(mod.StylooImportError, "SHA-256 distinto"):
            mod.validar_zip(self.zip, manifest, seleccion)

    def test_rechaza_zip_reempaquetado_por_defecto(self):
        otro = self.raiz / "repacked.zip"
        self._escribir_zip(otro, comentario=b"repacked")
        manifest = mod.cargar_manifiesto(self.manifest)
        seleccion = mod.seleccionar_assets(manifest, ["administrativo"])
        with self.assertRaisesRegex(mod.StylooImportError, "ZIP no coincide"):
            mod.validar_zip(otro, manifest, seleccion)

    def test_acepta_reempaquetado_si_los_glb_siguen_identicos(self):
        otro = self.raiz / "repacked.zip"
        self._escribir_zip(otro, comentario=b"repacked")
        manifest = mod.cargar_manifiesto(self.manifest)
        seleccion = mod.seleccionar_assets(manifest, ["administrativo"])
        extraidos = mod.validar_zip(
            otro, manifest, seleccion, aceptar_reempaquetado=True
        )
        self.assertEqual(extraidos["desk"], b"desk-real")

    def test_staging_no_pisa_ficheros_ajenos(self):
        manifest = mod.cargar_manifiesto(self.manifest)
        seleccion = mod.seleccionar_assets(manifest, ["administrativo"])
        extraidos = mod.validar_zip(self.zip, manifest, seleccion)
        salida = self.raiz / "staging"
        salida.mkdir()
        (salida / "manual.txt").write_text("no tocar", encoding="utf-8")
        with self.assertRaisesRegex(mod.StylooImportError, "ficheros ajenos"):
            mod.preparar_staging(salida, manifest, seleccion, extraidos)


if __name__ == "__main__":
    unittest.main()
