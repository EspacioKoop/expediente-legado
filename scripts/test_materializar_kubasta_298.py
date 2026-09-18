import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
import zipfile

SCRIPTS = Path(__file__).resolve().parent
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

SPEC = importlib.util.spec_from_file_location(
    "materializar_kubasta_298", SCRIPTS / "materializar_kubasta_298.py"
)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class MaterializarKubasta298Test(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        (self.repo / "godot/assets").mkdir(parents=True)
        (self.repo / ".gitattributes").write_text(
            "*.ttf filter=lfs diff=lfs merge=lfs -text\n", encoding="utf-8"
        )
        self.procedencia = {"_regla": "fixture", "assets": []}
        (self.repo / mod.PROCEDENCIA_REL).write_text(
            json.dumps(self.procedencia), encoding="utf-8"
        )

    def tearDown(self):
        self.tmp.cleanup()

    def _zip_fixture(self, contenido: bytes) -> Path:
        ruta = self.repo / "Kubasta.zip"
        with zipfile.ZipFile(ruta, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            zf.writestr(mod.MIEMBRO_TTF, contenido)
        return ruta

    def test_ficha_registra_origen_hash_y_paquete(self):
        ficha = mod.entrada_procedencia("a" * 64)
        self.assertEqual(ficha["ruta"], "fonts/Kubasta.ttf")
        self.assertEqual(ficha["licencia"], "CC0-1.0")
        self.assertEqual(ficha["fuente"], "https://zichy.itch.io/kubasta")
        self.assertEqual(ficha["sha256"], mod.FUENTE_SHA256)
        self.assertEqual(ficha["archivo_origen"], "Kubasta/Kubasta.ttf")
        self.assertEqual(ficha["paquete_sha256"], "a" * 64)

    def test_fusion_es_idempotente_y_no_sobrescribe(self):
        ficha = mod.entrada_procedencia("a" * 64)
        datos, añadida = mod.fusionar_procedencia(copy.deepcopy(self.procedencia), ficha)
        self.assertTrue(añadida)
        iguales, añadida_otra = mod.fusionar_procedencia(copy.deepcopy(datos), ficha)
        self.assertFalse(añadida_otra)
        self.assertEqual(iguales, datos)
        distinta = {**ficha, "sha256": "b" * 64}
        with self.assertRaisesRegex(mod.MaterializacionError, "ficha distinta"):
            mod.fusionar_procedencia(copy.deepcopy(datos), distinta)

    def test_valida_zip_por_hash_tamano_y_miembro(self):
        contenido = b"kubasta-fixture"
        ruta = self._zip_fixture(contenido)
        paquete_sha = mod.sha256_fichero(ruta)
        fuente_sha = hashlib.sha256(contenido).hexdigest()
        with (
            mock.patch.object(mod, "PAQUETE_SHA256", paquete_sha),
            mock.patch.object(mod, "FUENTE_SHA256", fuente_sha),
            mock.patch.object(mod, "FUENTE_BYTES", len(contenido)),
        ):
            leido, hash_zip = mod.validar_zip(ruta)
        self.assertEqual(leido, contenido)
        self.assertEqual(hash_zip, paquete_sha)

    def test_reempaquetado_solo_relaja_hash_del_contenedor(self):
        contenido = b"mismo-ttf"
        ruta = self._zip_fixture(contenido)
        fuente_sha = hashlib.sha256(contenido).hexdigest()
        with (
            mock.patch.object(mod, "PAQUETE_SHA256", "0" * 64),
            mock.patch.object(mod, "FUENTE_SHA256", fuente_sha),
            mock.patch.object(mod, "FUENTE_BYTES", len(contenido)),
        ):
            with self.assertRaisesRegex(mod.MaterializacionError, "ZIP distinto"):
                mod.validar_zip(ruta)
            leido, _ = mod.validar_zip(ruta, aceptar_reempaquetado=True)
        self.assertEqual(leido, contenido)

    def test_puntero_lfs_es_canonicamente_exacto(self):
        bueno = (
            "version https://git-lfs.github.com/spec/v1\n"
            f"oid sha256:{mod.FUENTE_SHA256}\n"
            f"size {mod.FUENTE_BYTES}\n"
        ).encode("ascii")
        self.assertTrue(mod.puntero_lfs_correcto(bueno))
        self.assertFalse(mod.puntero_lfs_correcto(bueno + b"extra\n"))
        self.assertFalse(mod.puntero_lfs_correcto(b"TTF-binario"))

    @mock.patch.object(mod, "ejecutar_git")
    def test_checkout_aplicar_exige_lfs_y_atributo_ttf(self, ejecutar_git):
        ejecutar_git.side_effect = [
            str(self.repo) + "\n",
            "git-lfs/3.7.0\n",
            "Updated Git hooks.\n",
            "godot/assets/fonts/Kubasta.ttf: filter: lfs\n",
        ]
        mod.validar_checkout(self.repo, exigir_lfs=True)
        self.assertEqual(ejecutar_git.call_args_list[1].args[1], ["lfs", "version"])
        self.assertEqual(
            ejecutar_git.call_args_list[2].args[1], ["lfs", "install", "--local"]
        )

    @mock.patch.object(mod, "ejecutar_git")
    def test_checkout_rechaza_fuente_fuera_de_lfs(self, ejecutar_git):
        ejecutar_git.side_effect = [
            str(self.repo) + "\n",
            "godot/assets/fonts/Kubasta.ttf: filter: unspecified\n",
        ]
        with self.assertRaisesRegex(mod.MaterializacionError, "no está cubierto"):
            mod.validar_checkout(self.repo, exigir_lfs=False)


if __name__ == "__main__":
    unittest.main()
