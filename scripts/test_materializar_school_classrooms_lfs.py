import pathlib
import subprocess
import tempfile
import unittest

from scripts.materializar_school_classrooms_styloo import (
    DESTINO_REL,
    MaterializacionError,
    verificar_indice_lfs,
)


def _crear_puntero_lfs(sha256: str, size: int) -> bytes:
    return (
        f"version https://git-lfs.github.com/spec/v1\n"
        f"oid sha256:{sha256}\n"
        f"size {size}\n"
    ).encode("ascii")


class TestVerificarIndiceLFS(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = pathlib.Path(self.tmp.name)
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

        self.asset_valid_sha256 = "1111111111111111111111111111111111111111111111111111111111111111"
        self.asset_valid_size = 1024
        self.asset_valid = {
            "id": "desk",
            "destino_sugerido": "desk.glb",
            "sha256": self.asset_valid_sha256,
            "bytes": self.asset_valid_size,
        }

        self.asset_invalid = {
            "id": "chair",
            "destino_sugerido": "chair.glb",
            "sha256": "2222222222222222222222222222222222222222222222222222222222222222",
            "bytes": 2048,
        }

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _preparar_fichero_en_indice(self, destino_sugerido: str, contenido: bytes) -> None:
        ruta = self.repo / DESTINO_REL / destino_sugerido
        ruta.parent.mkdir(parents=True, exist_ok=True)
        ruta.write_bytes(contenido)
        subprocess.run(["git", "add", "."], cwd=self.repo, check=True, capture_output=True)

    def test_verificar_indice_lfs_exito_con_puntero_valido(self) -> None:
        puntero = _crear_puntero_lfs(self.asset_valid_sha256, self.asset_valid_size)
        self._preparar_fichero_en_indice(self.asset_valid["destino_sugerido"], puntero)

        # No debe lanzar ninguna excepción cuando el índice contiene un puntero LFS válido
        verificar_indice_lfs(self.repo, [self.asset_valid])

    def test_verificar_indice_lfs_error_contenido_binario_sin_lfs(self) -> None:
        contenido_binario = b"glTF \x02\x00\x00\x00\x00\x00\x00\x00"
        self._preparar_fichero_en_indice(self.asset_valid["destino_sugerido"], contenido_binario)

        with self.assertRaises(MaterializacionError) as ctx:
            verificar_indice_lfs(self.repo, [self.asset_valid])
        self.assertIn("El índice no contiene un puntero LFS válido", str(ctx.exception))

    def test_verificar_indice_lfs_error_sha256_mismatched(self) -> None:
        otro_sha = "9999999999999999999999999999999999999999999999999999999999999999"
        puntero = _crear_puntero_lfs(otro_sha, self.asset_valid_size)
        self._preparar_fichero_en_indice(self.asset_valid["destino_sugerido"], puntero)

        with self.assertRaises(MaterializacionError) as ctx:
            verificar_indice_lfs(self.repo, [self.asset_valid])
        self.assertIn("El índice no contiene un puntero LFS válido", str(ctx.exception))

    def test_verificar_indice_lfs_error_bytes_mismatched(self) -> None:
        puntero = _crear_puntero_lfs(self.asset_valid_sha256, 99999)
        self._preparar_fichero_en_indice(self.asset_valid["destino_sugerido"], puntero)

        with self.assertRaises(MaterializacionError) as ctx:
            verificar_indice_lfs(self.repo, [self.asset_valid])
        self.assertIn("El índice no contiene un puntero LFS válido", str(ctx.exception))

    def test_verificar_indice_lfs_error_archivo_no_en_indice(self) -> None:
        with self.assertRaises(MaterializacionError) as ctx:
            verificar_indice_lfs(self.repo, [self.asset_valid])
        self.assertIn("git show :", str(ctx.exception))

    def test_verificar_indice_lfs_seleccion_sintetica_cubierto_y_no_cubierto(self) -> None:
        # Fichero 1: LFS válido
        puntero1 = _crear_puntero_lfs(self.asset_valid_sha256, self.asset_valid_size)
        self._preparar_fichero_en_indice(self.asset_valid["destino_sugerido"], puntero1)

        # Fichero 2: Binario crudo sin LFS
        contenido_binario = b"RAW BINARY DATA FOR CHAIR"
        self._preparar_fichero_en_indice(self.asset_invalid["destino_sugerido"], contenido_binario)

        seleccion = [self.asset_valid, self.asset_invalid]
        with self.assertRaises(MaterializacionError) as ctx:
            verificar_indice_lfs(self.repo, seleccion)
        self.assertIn("chair.glb", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
