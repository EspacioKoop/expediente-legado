import importlib.util
import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path

MOD_PATH = Path(__file__).with_name("preparar_texturas_pbr.py")
SPEC = importlib.util.spec_from_file_location("preparar_texturas_pbr", MOD_PATH)
MOD = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MOD
assert SPEC.loader is not None
SPEC.loader.exec_module(MOD)


def png_falso(path: Path, ancho: int, alto: int) -> None:
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + struct.pack(">I", 13)
        + b"IHDR"
        + struct.pack(">II", ancho, alto)
        + b"\x08\x02\x00\x00\x00"
        + b"\x00\x00\x00\x00"
    )


def jpeg_falso(path: Path, ancho: int, alto: int) -> None:
    sof = (
        b"\xff\xc0"
        + struct.pack(">H", 17)
        + b"\x08"
        + struct.pack(">HH", alto, ancho)
        + b"\x03\x01\x11\x00\x02\x11\x00\x03\x11\x00"
    )
    path.write_bytes(b"\xff\xd8" + sof + b"\xff\xd9")


class PrepararTexturasPbrTest(unittest.TestCase):
    def _set_valido(self, root: Path, size: int = 4096) -> Path:
        source = root / "source"
        source.mkdir()
        jpeg_falso(source / "albedo.jpg", size, size)
        png_falso(source / "normal.png", size, size)
        png_falso(source / "roughness.png", size, size)
        png_falso(source / "ao.png", size, size)
        return source

    def test_valida_set_4k_y_genera_compatibilidad(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = self._set_valido(root)
            assets = root / "godot" / "assets"
            fragmento = MOD.preparar(
                source,
                "acera_barcelona",
                assets,
                autor="Equipo arte",
                licencia="CC0-1.0",
                fuente="asset original #399",
            )
            self.assertEqual(fragmento["resolucion"], "4096x4096")
            self.assertTrue((assets / "texturas/acera_barcelona.jpg").is_file())
            self.assertTrue((assets / "texturas/pbr/acera_barcelona/normal.png").is_file())
            rutas = {entrada["ruta"] for entrada in fragmento["procedencia"]}
            self.assertIn("texturas/acera_barcelona.jpg", rutas)
            self.assertIn("texturas/pbr/acera_barcelona/ao.png", rutas)
            escrito = json.loads(
                (assets / "texturas/pbr/acera_barcelona/procedencia.fragment.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(escrito["material"], "acera_barcelona")
            self.assertTrue(all(len(e["sha256"]) == 64 for e in escrito["procedencia"]))

    def test_rechaza_resolucion_menor_de_4k(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = self._set_valido(root, 2048)
            with self.assertRaisesRegex(ValueError, "mínimo 4096x4096"):
                MOD.validar_set(source)

    def test_rechaza_set_incompleto(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = self._set_valido(root)
            (source / "ao.png").unlink()
            with self.assertRaisesRegex(ValueError, "mapa ao"):
                MOD.validar_set(source)

    def test_rechaza_albedo_png_si_se_pide_compatibilidad_actual(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "source"
            source.mkdir()
            for tipo in MOD.MAPAS:
                png_falso(source / f"{tipo}.png", 4096, 4096)
            with self.assertRaisesRegex(ValueError, "requiere albedo.jpg/jpeg"):
                MOD.preparar(
                    source,
                    "asfalto_urbano",
                    root / "assets",
                    autor="Equipo arte",
                    licencia="CC0-1.0",
                    fuente="asset original #399",
                )

    def test_metadatos_de_procedencia_son_obligatorios(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = self._set_valido(root)
            with self.assertRaisesRegex(ValueError, "son obligatorios"):
                MOD.preparar(
                    source,
                    "fachada_edificio",
                    root / "assets",
                    autor="",
                    licencia="CC0-1.0",
                    fuente="asset original #399",
                )


if __name__ == "__main__":
    unittest.main()
