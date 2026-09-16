import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

MODULO_RUTA = Path(__file__).with_name("import_tarot_cc0.py")
SPEC = importlib.util.spec_from_file_location("import_tarot_cc0", MODULO_RUTA)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
import sys
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def png_falso(ancho=200, alto=375):
    return b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR" + struct.pack(">II", ancho, alto)


class ImportTarotCC0Test(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.raiz = Path(self.tmp.name)
        nombres = {
            0: "00-The-Fool.png",
            1: "01-The-Magician.png",
            2: "02-The-High-Priestess.png",
            3: "03-The-Empress.png",
            4: "04-The-Emperor.png",
            5: "05-The-Pope.png",
            6: "06-The-Lovers.png",
            7: "07-The-Chariot.png",
            8: "08-Justice.png",
            9: "09-The-Hermit.png",
            10: "10-The-Wheel-of-Fortune.png",
            11: "11-Strength.png",
            12: "12-The-Hanged-Man.png",
            13: "13-Death.png",
            14: "14-Temperance.png",
            15: "15-The-Devil.png",
            16: "16-The-Tower.png",
            17: "17-The-Star.png",
            18: "18-The-Moon.png",
            19: "19-The-Sun.png",
            20: "20-The-Judgment.png",
            21: "21-The-World.png",
        }
        for numero, nombre in nombres.items():
            (self.raiz / nombre).write_bytes(png_falso())

    def tearDown(self):
        self.tmp.cleanup()

    def test_mapa_cubre_los_22_ids_reales_del_proyecto(self):
        repo = Path(__file__).resolve().parents[1]
        datos = json.loads((repo / "godot/datos/prometeo.json").read_text(encoding="utf-8"))
        ids_reales = {carta["id"] for carta in datos["tarot"]}
        self.assertEqual(ids_reales, set(mod.POR_ID))
        self.assertEqual(len(ids_reales), 22)

    def test_marsella_no_intercambia_justicia_y_fuerza(self):
        cartas = mod.descubrir_cartas(mod.leer_fuente(self.raiz))
        self.assertEqual(cartas["la-justicia"].nombre, "08-Justice.png")
        self.assertEqual(cartas["la-fuerza"].nombre, "11-Strength.png")

    def test_acepta_zip_sin_depender_del_orden_del_archivo(self):
        zip_ruta = self.raiz / "tarot.zip"
        with zipfile.ZipFile(zip_ruta, "w") as archivo:
            for fichero in sorted(self.raiz.glob("*.png"), reverse=True):
                archivo.writestr(f"tarot/{fichero.name}", fichero.read_bytes())
        imagenes = mod.leer_fuente(zip_ruta)
        cartas = mod.descubrir_cartas(imagenes)
        self.assertEqual(len(cartas), 22)
        self.assertEqual(cartas["la-justicia"].nombre, "tarot/08-Justice.png")

    def test_rechaza_dimensiones_distintas_de_200_por_375(self):
        (self.raiz / "17-The-Star.png").write_bytes(png_falso(201, 375))
        with self.assertRaisesRegex(mod.TarotImportError, "201x375"):
            mod.descubrir_cartas(mod.leer_fuente(self.raiz))

    def test_rechaza_arcano_duplicado_aunque_haya_22_imagenes(self):
        (self.raiz / "19-The-Sun.png").unlink()
        (self.raiz / "99-World-copy.png").write_bytes(png_falso())
        with self.assertRaisesRegex(mod.TarotImportError, "Arcano duplicado"):
            mod.descubrir_cartas(mod.leer_fuente(self.raiz))

    def test_staging_usa_ids_y_emite_hashes_reales(self):
        cartas = mod.descubrir_cartas(mod.leer_fuente(self.raiz))
        salida = self.raiz / "staging"
        manifiesto = mod.preparar_staging(cartas, salida)
        self.assertEqual(manifiesto["cantidad"], 22)
        self.assertTrue((salida / "el-loco.png").exists())
        self.assertTrue((salida / "la-justicia.png").exists())
        self.assertTrue((salida / "la-fuerza.png").exists())
        self.assertTrue((salida / "el-mundo.png").exists())
        self.assertEqual(len(list(salida.glob("*.png"))), 22)
        for entrada in manifiesto["cartas"]:
            self.assertRegex(entrada["sha256"], r"^[0-9a-f]{64}$")
        guardado = json.loads((salida / "tarot-cc0-manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(guardado["fuente"], mod.FUENTE)
        self.assertEqual(guardado["licencia"], "CC0-1.0")


if __name__ == "__main__":
    unittest.main()
