from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
SCRIPT = RAIZ / "scripts" / "preparar_horror_texture_pack.py"
MANIFIESTO = RAIZ / "docs" / "assets" / "horror-texture-pack.manifest.json"

spec = importlib.util.spec_from_file_location("preparar_horror_texture_pack", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


def png_minimo(path: Path, lado: int = 128, color_type: int = 6) -> None:
    import struct
    import zlib

    def chunk(tipo: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tipo
            + data
            + struct.pack(">I", zlib.crc32(tipo + data))
        )

    cabecera = struct.pack(">IIBBBBB", lado, lado, 8, color_type, 0, 0, 0)
    canales = 4 if color_type == 6 else 3
    fila = b"\x00" + bytes([0] * lado * canales)
    datos = zlib.compress(fila * lado)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", cabecera)
        + chunk(b"IDAT", datos)
        + chunk(b"IEND", b"")
    )


class HorrorTexturePackTest(unittest.TestCase):
    def test_manifiesto_fija_los_tres_rar_auditados(self) -> None:
        datos = json.loads(MANIFIESTO.read_text(encoding="utf-8"))
        self.assertEqual(
            datos["archivos_fuente"]["128"]["sha256"],
            "1fee483ce0253e64096442a2c16833ec9da90bdfa2836e5d54a061f293abf6fb",
        )
        self.assertEqual(
            datos["archivos_fuente"]["256"]["sha256"],
            "6c78d279ce669d548ce77adf6dd768e40e1436498326a0bbce578f82cab6e9f0",
        )
        self.assertEqual(
            datos["archivos_fuente"]["512"]["sha256"],
            "29feed70b77a17b974cce79a4f343f5f4fdf8f56cec0af91335083bf4cceaae4",
        )
        self.assertEqual(sum(datos["categorias"].values()), 100)

    def test_perfiles_por_defecto_no_incluyen_sangre(self) -> None:
        datos = modulo.leer_manifiesto(MANIFIESTO)
        seleccion = modulo._seleccion(datos, modulo.PERFILES_POR_DEFECTO, False)
        excluidos = set(datos["excluidos_automaticos"])
        self.assertFalse(excluidos.intersection(seleccion))
        self.assertIn("sueno_escuela", datos["perfiles"])
        self.assertIn("sueno_castillo", datos["perfiles"])
        self.assertIn("sueno_desierto", datos["perfiles"])

    def test_prepara_asset_y_fragmento_sin_tocar_procedencia_global(self) -> None:
        datos = modulo.leer_manifiesto(MANIFIESTO)
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            extraido = base / "extraido" / "128x128"
            identificador = "Stains/Horror_Stain_10"
            png = extraido / "Stains" / "Horror_Stain_10-128x128.png"
            png_minimo(png)
            assets = base / "assets"
            fragmento = modulo.preparar_desde_carpeta(
                extraido,
                128,
                [identificador],
                assets,
                datos,
                datos["archivos_fuente"]["128"]["sha256"],
            )
            salida = assets / fragmento["archivos"][0]
            self.assertTrue(salida.is_file())
            self.assertEqual(modulo.sha256(salida), fragmento["procedencia"][0]["sha256"])
            self.assertTrue(
                (assets / "texturas/horror_sbs/128x128/procedencia.fragment.json").is_file()
            )
            self.assertFalse((assets / "procedencia.json").exists())

    def test_rechaza_mancha_sin_alpha(self) -> None:
        datos = modulo.leer_manifiesto(MANIFIESTO)
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            extraido = base / "128x128"
            png = extraido / "Stains" / "Horror_Stain_10-128x128.png"
            png_minimo(png, color_type=2)
            with self.assertRaisesRegex(ValueError, "canal alfa"):
                modulo.preparar_desde_carpeta(
                    extraido,
                    128,
                    ["Stains/Horror_Stain_10"],
                    base / "assets",
                    datos,
                    datos["archivos_fuente"]["128"]["sha256"],
                )


if __name__ == "__main__":
    unittest.main()
