import hashlib
import importlib.util
from pathlib import Path
import sys
import unittest
from unittest import mock

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


class MaterializarKubastaLfsTest(unittest.TestCase):
    def test_sha256_bytes_coincide_con_hashlib(self):
        casos = [
            b"",
            b"test data",
            b"\x00\xff" * 100,
            b"Kubasta font content binary mock",
        ]
        for contenido in casos:
            with self.subTest(contenido=contenido):
                esperado = hashlib.sha256(contenido).hexdigest()
                resultado = mod.sha256_bytes(contenido)
                self.assertEqual(resultado, esperado)

    @mock.patch.object(mod, "ejecutar_git")
    def test_verificar_indice_lfs_exito_con_puntero_canonico(self, mock_ejecutar_git):
        puntero_valido = (
            f"version https://git-lfs.github.com/spec/v1\n"
            f"oid sha256:{mod.FUENTE_SHA256}\n"
            f"size {mod.FUENTE_BYTES}\n"
        ).encode("ascii")
        mock_ejecutar_git.return_value = puntero_valido

        repo = Path("/tmp/fake_repo")
        mod.verificar_indice_lfs(repo)

        mock_ejecutar_git.assert_called_once_with(
            repo, ["show", f":{mod.DESTINO_REL.as_posix()}"], binario=True
        )

    @mock.patch.object(mod, "ejecutar_git")
    def test_verificar_indice_lfs_falla_si_puntero_invalido(self, mock_ejecutar_git):
        punteros_invalidos = [
            b"contenido no lfs",
            (
                f"version https://git-lfs.github.com/spec/v1\n"
                f"oid sha256:0000000000000000000000000000000000000000000000000000000000000000\n"
                f"size {mod.FUENTE_BYTES}\n"
            ).encode("ascii"),
            (
                f"version https://git-lfs.github.com/spec/v1\n"
                f"oid sha256:{mod.FUENTE_SHA256}\n"
                f"size 12345\n"
            ).encode("ascii"),
            b"",
        ]
        repo = Path("/tmp/fake_repo")
        for contenido in punteros_invalidos:
            with self.subTest(contenido=contenido):
                mock_ejecutar_git.return_value = contenido
                with self.assertRaisesRegex(
                    mod.MaterializacionError, "puntero LFS canónico"
                ):
                    mod.verificar_indice_lfs(repo)

    @mock.patch.object(mod, "ejecutar_git")
    def test_verificar_indice_lfs_falla_si_git_falla(self, mock_ejecutar_git):
        mock_ejecutar_git.side_effect = mod.MaterializacionError("git show falló")
        repo = Path("/tmp/fake_repo")
        with self.assertRaisesRegex(mod.MaterializacionError, "git show falló"):
            mod.verificar_indice_lfs(repo)


if __name__ == "__main__":
    unittest.main()
