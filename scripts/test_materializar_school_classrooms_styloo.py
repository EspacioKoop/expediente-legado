import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

SCRIPTS = Path(__file__).resolve().parent
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

PREP_SPEC = importlib.util.spec_from_file_location(
    "preparar_school_classrooms_styloo", SCRIPTS / "preparar_school_classrooms_styloo.py"
)
prep = importlib.util.module_from_spec(PREP_SPEC)
assert PREP_SPEC and PREP_SPEC.loader
sys.modules[PREP_SPEC.name] = prep
PREP_SPEC.loader.exec_module(prep)

SPEC = importlib.util.spec_from_file_location(
    "materializar_school_classrooms_styloo", SCRIPTS / "materializar_school_classrooms_styloo.py"
)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class MaterializarSchoolClassroomsStylooTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        (self.repo / "godot/assets").mkdir(parents=True)
        (self.repo / ".gitattributes").write_text(
            "*.glb filter=lfs diff=lfs merge=lfs -text\n", encoding="utf-8"
        )
        self.procedencia = {
            "_regla": "fixture",
            "assets": [
                {
                    "ruta": "modelos/existente.glb",
                    "titulo": "existente",
                    "autor": "otro",
                    "licencia": "CC0-1.0",
                    "fuente": "https://example.invalid",
                    "sha256": "a" * 64,
                }
            ],
        }
        (self.repo / mod.PROCEDENCIA_REL).write_text(
            json.dumps(self.procedencia), encoding="utf-8"
        )
        self.manifiesto = {
            "autor": "styloo",
            "licencia": "CC0-1.0",
            "fuente": "https://styloo.itch.io/classroom-asset-pack",
            "archivo_sha256": "b" * 64,
        }
        self.asset = {
            "id": "desk",
            "titulo": "Principal Office desk",
            "miembro_zip": "pack/principal/desk.glb",
            "destino_sugerido": "principal_office_desk.glb",
            "bytes": 9,
            "sha256": "c" * 64,
        }

    def tearDown(self):
        self.tmp.cleanup()

    def test_ficha_incluye_origen_y_hash_del_paquete(self):
        entrada = mod.entrada_procedencia(self.asset, self.manifiesto)
        self.assertEqual(
            entrada["ruta"], "modelos/styloo_school/principal_office_desk.glb"
        )
        self.assertEqual(entrada["archivo_origen"], "pack/principal/desk.glb")
        self.assertEqual(entrada["paquete_sha256"], "b" * 64)
        self.assertEqual(entrada["sha256"], "c" * 64)

    def test_fusion_de_procedencia_es_idempotente(self):
        entrada = mod.entrada_procedencia(self.asset, self.manifiesto)
        primera, añadidas = mod.fusionar_procedencia(copy.deepcopy(self.procedencia), [entrada])
        self.assertEqual(len(añadidas), 1)
        segunda, añadidas_segunda = mod.fusionar_procedencia(copy.deepcopy(primera), [entrada])
        self.assertEqual(añadidas_segunda, [])
        self.assertEqual(segunda, primera)

    def test_no_sobrescribe_misma_ruta_con_hash_distinto(self):
        entrada = mod.entrada_procedencia(self.asset, self.manifiesto)
        datos = copy.deepcopy(self.procedencia)
        datos["assets"].append({**entrada, "sha256": "d" * 64})
        with self.assertRaisesRegex(mod.MaterializacionError, "ficha distinta"):
            mod.fusionar_procedencia(datos, [entrada])

    def test_rechaza_destino_existente_distinto(self):
        destino = self.repo / mod.DESTINO_REL / self.asset["destino_sugerido"]
        destino.parent.mkdir(parents=True)
        destino.write_bytes(b"contenido-ajeno")
        with self.assertRaisesRegex(mod.MaterializacionError, "contenido distinto"):
            mod.validar_destinos(self.repo, [self.asset])

    def test_puntero_lfs_debe_coincidir_en_oid_y_tamano(self):
        asset = {**self.asset, "sha256": "1" * 64, "bytes": 321}
        bueno = (
            "version https://git-lfs.github.com/spec/v1\n"
            f"oid sha256:{'1' * 64}\n"
            "size 321\n"
        ).encode("ascii")
        malo = bueno.replace(b"size 321", b"size 320")
        self.assertTrue(mod.puntero_lfs_correcto(bueno, asset))
        self.assertFalse(mod.puntero_lfs_correcto(malo, asset))
        self.assertFalse(mod.puntero_lfs_correcto(b"GLB-binario", asset))

    @mock.patch.object(mod, "ejecutar_git")
    def test_rechaza_rutas_con_cambios_locales(self, ejecutar_git):
        ejecutar_git.return_value = " M godot/assets/procedencia.json\n"
        with self.assertRaisesRegex(mod.MaterializacionError, "cambios locales"):
            mod.validar_rutas_limpias(self.repo, [mod.PROCEDENCIA_REL])

    @mock.patch.object(mod, "ejecutar_git")
    def test_checkout_aplicar_exige_git_lfs_y_atributo(self, ejecutar_git):
        ejecutar_git.side_effect = [
            str(self.repo) + "\n",
            "git-lfs/3.7.0\n",
            "Updated Git hooks.\n",
            "godot/assets/modelos/styloo_school/principal_office_desk.glb: filter: lfs\n",
        ]
        mod.validar_checkout(
            self.repo,
            [mod.DESTINO_REL / self.asset["destino_sugerido"]],
            exigir_lfs=True,
        )
        self.assertEqual(ejecutar_git.call_args_list[1].args[1], ["lfs", "version"])
        self.assertEqual(
            ejecutar_git.call_args_list[2].args[1], ["lfs", "install", "--local"]
        )

    @mock.patch.object(mod, "ejecutar_git")
    def test_checkout_rechaza_glb_fuera_de_lfs(self, ejecutar_git):
        ejecutar_git.side_effect = [
            str(self.repo) + "\n",
            "git-lfs/3.7.0\n",
            "Updated Git hooks.\n",
            "x: filter: unspecified\n",
        ]
        with self.assertRaisesRegex(mod.MaterializacionError, "no está cubierto"):
            mod.validar_checkout(
                self.repo,
                [mod.DESTINO_REL / self.asset["destino_sugerido"]],
                exigir_lfs=True,
            )


if __name__ == "__main__":
    unittest.main()
