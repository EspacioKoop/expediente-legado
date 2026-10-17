import importlib.util
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "materializar_street_furniture_680",
    SCRIPTS / "materializar_street_furniture_680.py",
)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class TestMaterializarStreetFurnitureRutas(unittest.TestCase):
    def test_rutas_destino_retorna_rutas_esperadas(self):
        seleccion = mod.seleccionar(["crowbar", "flashlight"])
        rutas = mod.rutas_destino(seleccion)

        esperadas = [
            mod.DESTINO_REL / "Crowbar.glb",
            mod.DESTINO_REL / "Crowbar_Crowbar_albedo.png",
            mod.DESTINO_REL / "Flashlight.glb",
            mod.DESTINO_REL / "Flashlight_Flashlight_albedo.png",
        ]
        self.assertEqual(rutas, esperadas)

    def test_rutas_destino_seleccion_sintetica_no_sale_del_arbol(self):
        seleccion_sintetica = [
            (
                "sintetico_1",
                {"glb": "Sintetico.glb", "png": "Sintetico.png"},
            ),
            (
                "sintetico_2",
                {"glb": "Subfolder/Otro.glb", "png": "Subfolder/Otro.png"},
            ),
        ]
        rutas = mod.rutas_destino(seleccion_sintetica)

        for ruta in rutas:
            self.assertTrue(
                ruta.is_relative_to(mod.DESTINO_REL),
                f"La ruta {ruta} debe estar dentro de {mod.DESTINO_REL}",
            )
            self.assertNotIn("..", ruta.parts)

    @patch("materializar_street_furniture_680.ejecutar_git")
    def test_verificar_indice_lfs_correcto(self, mock_ejecutar_git):
        sha_glb = "a" * 64
        sha_png = "b" * 64
        size_glb = 100
        size_png = 200

        seleccion = [
            ("sintetico", {"glb": "Objeto.glb", "png": "Objeto.png"}),
        ]
        preparados = {
            "sintetico": {
                "glb_sha256": sha_glb,
                "glb_bytes": size_glb,
                "png_sha256": sha_png,
                "png_bytes": size_png,
            }
        }

        puntero_glb = (
            "version https://git-lfs.github.com/spec/v1\n"
            f"oid sha256:{sha_glb}\n"
            f"size {size_glb}\n"
        ).encode("ascii")

        puntero_png = (
            "version https://git-lfs.github.com/spec/v1\n"
            f"oid sha256:{sha_png}\n"
            f"size {size_png}\n"
        ).encode("ascii")

        def side_effect(repo, args, binario=False):
            if ":godot/assets/modelos/street_furniture/Objeto.glb" in args[1]:
                return puntero_glb
            if ":godot/assets/modelos/street_furniture/Objeto.png" in args[1]:
                return puntero_png
            return b""

        mock_ejecutar_git.side_effect = side_effect

        repo = Path("/repo_ficticio")
        mod.verificar_indice_lfs(repo, seleccion, preparados)
        self.assertEqual(mock_ejecutar_git.call_count, 2)

    @patch("materializar_street_furniture_680.ejecutar_git")
    def test_verificar_indice_lfs_puntero_invalido_lanza_error(self, mock_ejecutar_git):
        seleccion = [
            ("sintetico", {"glb": "Objeto.glb", "png": "Objeto.png"}),
        ]
        preparados = {
            "sintetico": {
                "glb_sha256": "a" * 64,
                "glb_bytes": 100,
                "png_sha256": "b" * 64,
                "png_bytes": 200,
            }
        }

        mock_ejecutar_git.return_value = b"\x00\x01\x02\x03\x04"

        repo = Path("/repo_ficticio")
        with self.assertRaisesRegex(
            mod.MaterializacionError,
            "El índice no contiene puntero LFS válido para GLB godot/assets/modelos/street_furniture/Objeto.glb",
        ):
            mod.verificar_indice_lfs(repo, seleccion, preparados)

    @patch("materializar_street_furniture_680.ejecutar_git")
    def test_verificar_indice_lfs_error_git_propaga_excepcion(self, mock_ejecutar_git):
        mock_ejecutar_git.side_effect = mod.MaterializacionError("git show falló: fatal: path not in index")

        seleccion = [
            ("sintetico", {"glb": "Objeto.glb", "png": "Objeto.png"}),
        ]
        preparados = {
            "sintetico": {
                "glb_sha256": "a" * 64,
                "glb_bytes": 100,
                "png_sha256": "b" * 64,
                "png_bytes": 200,
            }
        }

        repo = Path("/repo_ficticio")
        with self.assertRaisesRegex(mod.MaterializacionError, "git show falló"):
            mod.verificar_indice_lfs(repo, seleccion, preparados)


if __name__ == "__main__":
    unittest.main()
