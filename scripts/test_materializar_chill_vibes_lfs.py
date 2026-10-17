import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

SCRIPTS = Path(__file__).resolve().parent
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

PREP_SPEC = importlib.util.spec_from_file_location(
    "preparar_chill_vibes_cc0", SCRIPTS / "preparar_chill_vibes_cc0.py"
)
prep = importlib.util.module_from_spec(PREP_SPEC)
assert PREP_SPEC and PREP_SPEC.loader
sys.modules[PREP_SPEC.name] = prep
PREP_SPEC.loader.exec_module(prep)

SPEC = importlib.util.spec_from_file_location(
    "materializar_chill_vibes_cc0", SCRIPTS / "materializar_chill_vibes_cc0.py"
)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class TestVerificarIndiceLFS(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        (self.repo / "godot/assets").mkdir(parents=True)
        self.asset_a = {
            "id": "pallet",
            "titulo": "Shipping pallet",
            "miembro_extraido": "3D/Shipping pallet/shipping_pallet.glb",
            "destino_sugerido": "shipping_pallet.glb",
            "bytes": 321,
            "sha256": "a" * 64,
        }
        self.asset_b = {
            "id": "crate",
            "titulo": "Crate",
            "miembro_extraido": "3D/Crate/crate.glb",
            "destino_sugerido": "crate.glb",
            "bytes": 500,
            "sha256": "b" * 64,
        }

    def tearDown(self):
        self.tmp.cleanup()

    def _crear_puntero_lfs(self, asset: dict) -> bytes:
        return (
            f"{mod.PUNTERO_LFS}"
            f"oid sha256:{asset['sha256']}\n"
            f"size {asset['bytes']}\n"
        ).encode("ascii")

    @mock.patch.object(mod, "ejecutar_git")
    def test_verificar_indice_lfs_valido(self, mock_ejecutar_git):
        puntero = self._crear_puntero_lfs(self.asset_a)
        mock_ejecutar_git.return_value = puntero

        # No debe lanzar excepción
        mod.verificar_indice_lfs(self.repo, [self.asset_a])

        mock_ejecutar_git.assert_called_once_with(
            self.repo,
            ["show", f":{(mod.DESTINO_REL / self.asset_a['destino_sugerido']).as_posix()}"],
            binario=True,
        )

    @mock.patch.object(mod, "ejecutar_git")
    def test_verificar_indice_lfs_puntero_invalido_lanza_error(self, mock_ejecutar_git):
        # Contenido binario (no LFS)
        mock_ejecutar_git.return_value = b"glTF binary content"

        rel = mod.DESTINO_REL / self.asset_a["destino_sugerido"]
        with self.assertRaises(mod.MaterializacionError) as cm:
            mod.verificar_indice_lfs(self.repo, [self.asset_a])

        self.assertIn("El índice no contiene un puntero LFS válido", str(cm.exception))
        self.assertIn(rel.as_posix(), str(cm.exception))

    @mock.patch.object(mod, "ejecutar_git")
    def test_verificar_indice_lfs_sha256_o_tamano_incorrecto(self, mock_ejecutar_git):
        # Puntero con SHA256 incorrecto
        puntero_corrupto = (
            f"{mod.PUNTERO_LFS}"
            f"oid sha256:{'f' * 64}\n"
            f"size {self.asset_a['bytes']}\n"
        ).encode("ascii")
        mock_ejecutar_git.return_value = puntero_corrupto

        with self.assertRaises(mod.MaterializacionError) as cm:
            mod.verificar_indice_lfs(self.repo, [self.asset_a])

        self.assertIn("El índice no contiene un puntero LFS válido", str(cm.exception))

    @mock.patch.object(mod, "ejecutar_git")
    def test_verificar_indice_lfs_fallo_git_propaga_error(self, mock_ejecutar_git):
        mock_ejecutar_git.side_effect = mod.MaterializacionError("git show falló")

        with self.assertRaises(mod.MaterializacionError) as cm:
            mod.verificar_indice_lfs(self.repo, [self.asset_a])

        self.assertEqual(str(cm.exception), "git show falló")

    def test_verificar_indice_lfs_seleccion_vacia(self):
        with mock.patch.object(mod, "ejecutar_git") as mock_ejecutar_git:
            mod.verificar_indice_lfs(self.repo, [])
            mock_ejecutar_git.assert_not_called()

    @mock.patch.object(mod, "ejecutar_git")
    def test_verificar_indice_lfs_multiples_assets_exito_y_fallo(self, mock_ejecutar_git):
        puntero_a = self._crear_puntero_lfs(self.asset_a)
        puntero_b = self._crear_puntero_lfs(self.asset_b)

        mock_ejecutar_git.side_effect = [puntero_a, puntero_b]
        mod.verificar_indice_lfs(self.repo, [self.asset_a, self.asset_b])

        # Si el segundo asset es inválido
        mock_ejecutar_git.side_effect = [puntero_a, b"invalid"]
        with self.assertRaises(mod.MaterializacionError):
            mod.verificar_indice_lfs(self.repo, [self.asset_a, self.asset_b])

    def test_verificar_indice_lfs_repo_git_real_con_lfs_attributes(self):
        # Repositorio git temporal real
        subprocess.run(["git", "init"], cwd=self.repo, check=True, capture_output=True)
        subprocess.run(
            ["git", "config", "user.name", "Test User"],
            cwd=self.repo,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "config", "user.email", "test@example.com"],
            cwd=self.repo,
            check=True,
            capture_output=True,
        )

        # Crear .gitattributes con filtro lfs
        (self.repo / ".gitattributes").write_text(
            "*.glb filter=lfs diff=lfs merge=lfs -text\n", encoding="utf-8"
        )

        destino_dir = self.repo / mod.DESTINO_REL
        destino_dir.mkdir(parents=True, exist_ok=True)

        fichero = destino_dir / self.asset_a["destino_sugerido"]
        puntero_bytes = self._crear_puntero_lfs(self.asset_a)
        fichero.write_bytes(puntero_bytes)

        subprocess.run(
            ["git", "add", fichero.as_posix()],
            cwd=self.repo,
            check=True,
            capture_output=True,
        )

        # Como hemos añadido directamente el contenido del puntero al índice, verificar_indice_lfs debe pasar
        mod.verificar_indice_lfs(self.repo, [self.asset_a])

    def test_verificar_indice_lfs_repo_git_real_sin_puntero_lfs_falla(self):
        subprocess.run(["git", "init"], cwd=self.repo, check=True, capture_output=True)
        subprocess.run(
            ["git", "config", "user.name", "Test User"],
            cwd=self.repo,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "config", "user.email", "test@example.com"],
            cwd=self.repo,
            check=True,
            capture_output=True,
        )

        # .gitattributes sin LFS o archivo binario plano
        (self.repo / ".gitattributes").write_text("*.glb binary\n", encoding="utf-8")

        destino_dir = self.repo / mod.DESTINO_REL
        destino_dir.mkdir(parents=True, exist_ok=True)

        fichero = destino_dir / self.asset_a["destino_sugerido"]
        fichero.write_bytes(b"\x00\x01\x02\x03\x04\x05")

        subprocess.run(
            ["git", "add", fichero.as_posix()],
            cwd=self.repo,
            check=True,
            capture_output=True,
        )

        with self.assertRaises(mod.MaterializacionError) as cm:
            mod.verificar_indice_lfs(self.repo, [self.asset_a])

        self.assertIn("El índice no contiene un puntero LFS válido", str(cm.exception))


if __name__ == "__main__":
    unittest.main()
