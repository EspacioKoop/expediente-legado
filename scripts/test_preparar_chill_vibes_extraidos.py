import hashlib
from pathlib import Path
import tempfile
import unittest

from scripts.preparar_chill_vibes_cc0 import (
    CARPETA_RAIZ,
    ChillVibesImportError,
    assets_por_id,
    resolver_raiz_extraida,
    validar_extraidos,
)


class TestPrepararChillVibesExtraidos(unittest.TestCase):
    def test_chill_vibes_import_error_hereda_de_runtime_error(self):
        self.assertTrue(issubclass(ChillVibesImportError, RuntimeError))
        err = ChillVibesImportError("Error de prueba")
        self.assertEqual(str(err), "Error de prueba")

    def test_resolver_raiz_extraida_directorio_inexistente_lanza_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            no_existe = Path(tmpdir) / "subcarpeta_inexistente"
            with self.assertRaises(ChillVibesImportError) as ctx:
                resolver_raiz_extraida(no_existe)
            self.assertIn("No existe el directorio extraído", str(ctx.exception))

    def test_resolver_raiz_extraida_fichero_en_vez_de_directorio_lanza_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            fichero = Path(tmpdir) / "fichero.txt"
            fichero.write_text("hola", encoding="utf-8")
            with self.assertRaises(ChillVibesImportError) as ctx:
                resolver_raiz_extraida(fichero)
            self.assertIn("No existe el directorio extraído", str(ctx.exception))

    def test_resolver_raiz_extraida_directa(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            raiz = Path(tmpdir)
            (raiz / "3D").mkdir()
            (raiz / "README.txt").write_text("Readme", encoding="utf-8")

            res = resolver_raiz_extraida(raiz)
            self.assertEqual(res, raiz)

    def test_resolver_raiz_extraida_anidada_con_varias_candidatas(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            raiz = Path(tmpdir)
            # Crear varias carpetas candidatas/distracciones
            (raiz / "Otra_Carpeta").mkdir()
            (raiz / "Docs").mkdir()
            (raiz / "Docs" / "README.txt").write_text("Otro readme", encoding="utf-8")

            # Crear la subcarpeta estándar
            candidata = raiz / CARPETA_RAIZ
            (candidata / "3D").mkdir(parents=True)
            (candidata / "README.txt").write_text("README oficial", encoding="utf-8")

            res = resolver_raiz_extraida(raiz)
            self.assertEqual(res, candidata)

    def test_resolver_raiz_extraida_sin_3d_o_readme_lanza_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            raiz = Path(tmpdir)
            (raiz / "3D").mkdir()
            # Falta README.txt
            with self.assertRaises(ChillVibesImportError) as ctx:
                resolver_raiz_extraida(raiz)
            self.assertIn("No encuentro la raíz extraída esperada", str(ctx.exception))

    def test_assets_por_id_devuelve_diccionario_mapeado_por_id(self):
        manifiesto = {
            "assets": [
                {"id": "barrel", "bytes": 100, "sha256": "abc"},
                {"id": "crate", "bytes": 200, "sha256": "def"},
            ]
        }
        res = assets_por_id(manifiesto)
        self.assertEqual(len(res), 2)
        self.assertEqual(res["barrel"]["bytes"], 100)
        self.assertEqual(res["crate"]["sha256"], "def")

    def test_assets_por_id_manifiesto_vacio(self):
        manifiesto = {"assets": []}
        res = assets_por_id(manifiesto)
        self.assertEqual(res, {})

    def test_validar_extraidos_exito(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            raiz = Path(tmpdir)
            contenido = b"contenido glb sintetico"
            sha256_esperado = hashlib.sha256(contenido).hexdigest()

            fichero_asset = raiz / "3D" / "item.glb"
            fichero_asset.parent.mkdir(parents=True, exist_ok=True)
            fichero_asset.write_bytes(contenido)

            seleccion = [
                {
                    "id": "test_asset",
                    "miembro_extraido": "3D/item.glb",
                    "bytes": len(contenido),
                    "sha256": sha256_esperado,
                }
            ]

            res = validar_extraidos(raiz, seleccion)
            self.assertEqual(res, {"test_asset": fichero_asset})

    def test_validar_extraidos_falta_fichero_lanza_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            raiz = Path(tmpdir)
            seleccion = [
                {
                    "id": "missing_asset",
                    "miembro_extraido": "3D/no_existe.glb",
                    "bytes": 10,
                    "sha256": "abc",
                }
            ]
            with self.assertRaises(ChillVibesImportError) as ctx:
                validar_extraidos(raiz, seleccion)
            self.assertIn("Falta el GLB auditado", str(ctx.exception))

    def test_validar_extraidos_tamano_distinto_lanza_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            raiz = Path(tmpdir)
            contenido = b"contenido"
            fichero_asset = raiz / "item.glb"
            fichero_asset.write_bytes(contenido)

            seleccion = [
                {
                    "id": "bad_size_asset",
                    "miembro_extraido": "item.glb",
                    "bytes": len(contenido) + 5,
                    "sha256": hashlib.sha256(contenido).hexdigest(),
                }
            ]
            with self.assertRaises(ChillVibesImportError) as ctx:
                validar_extraidos(raiz, seleccion)
            self.assertIn("tamaño distinto", str(ctx.exception))

    def test_validar_extraidos_hash_distinto_lanza_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            raiz = Path(tmpdir)
            contenido_real = b"contenido real alterado"
            fichero_asset = raiz / "item.glb"
            fichero_asset.write_bytes(contenido_real)

            hash_falso = "0" * 64
            seleccion = [
                {
                    "id": "bad_hash_asset",
                    "miembro_extraido": "item.glb",
                    "bytes": len(contenido_real),
                    "sha256": hash_falso,
                }
            ]
            with self.assertRaises(ChillVibesImportError) as ctx:
                validar_extraidos(raiz, seleccion)
            self.assertIn("SHA-256 distinto", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
