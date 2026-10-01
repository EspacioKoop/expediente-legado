import hashlib
import importlib.util
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GENERADOR = ROOT / "tools" / "sfx_chip" / "generar.py"
ASSETS = ROOT / "godot" / "assets"
PROCEDENCIA = ASSETS / "procedencia.json"
SONIDO = ROOT / "godot" / "guion" / "sonido.gd"
RUNTIME = {
    "archivador_abrir_01.ogg": "b690530a0e8f5774cb55dbb1ec26c338ef0f025a01a74064b495c99fabe70574",
    "archivador_abrir_02.ogg": "09239eba37382e39e676a847e374bac1d35bc3700984d2f1c17653f016d77a8a",
    "archivador_abrir_03.ogg": "2c8fff670229b3b387818844af7c5268d2b1fe821d88f70cb90df5b9d55a6074",
    "archivador_cerrar_01.ogg": "5dc7cdb111692b1f58e30f457d4595433d365f54aa789158fe461c4a0a4fdff4",
    "archivador_cerrar_02.ogg": "d7ec8cd0de8f6a6afd9f2662994c73e06aa572ef30d8f729ccf6602743ed6bcf",
    "archivador_cerrar_03.ogg": "b7597fcb04a74189035809268b47a2c1821e9482489e06cda450cda2fe83a277",
    "papel_coger_01.ogg": "ab7c79d10d10996bcd01f3550abdedf562e180f7b53295ad48b8e91365d075aa",
    "papel_pasar_01.ogg": "0d8c22e65257cf8f097a2225c679608a147f2b4c6e18b174b32cfac0c636a191",
    "papel_manojo_01.ogg": "9255d624eb107cb437d9d1be077ce4372c6cb29a4f5021290d7a9702441392ca",
}
ARCHIVADOR_WAV = {
    "archivador_abrir_01": "f2ffeb6b5bdf3f7bb34e108755ec561688af9ed368f4baf7656db7b84112fdc5",
    "archivador_abrir_02": "955612e51f50cfee151f61be36faadc441bc55b5013580d491d364a85af70024",
    "archivador_abrir_03": "1a1ac4635f0f5c3607b8a2c133dcb9fe6d052a410608d0f67c072963805e3be0",
    "archivador_cerrar_01": "8d820839175e0b2e2f411027845875323e7a38873ae08ad18e85dd175ee3d935",
    "archivador_cerrar_02": "b52f5bfe6a0654577b45b0f51ce29f76e7f54fcaed53bed65ec879e2f0b35b3d",
    "archivador_cerrar_03": "7c6650547bbb11dfaf72afb931bf014f3686eeb19f69c583d6ada42a17898dfe",
}

spec = importlib.util.spec_from_file_location("sfx_chip_generar", GENERADOR)
generador = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(generador)


class SfxChipGeneradorTest(unittest.TestCase):
    def test_recetas_regeneran_el_pcm_canonico(self):
        for nombre, esperado in ARCHIVADOR_WAV.items():
            self.assertIn(nombre, generador.RECETAS)
            self.assertEqual(generador.RECETAS[nombre]["wav_sha256"], esperado, nombre)

        hashes = set()
        for nombre, receta in generador.RECETAS.items():
            wav = generador.wav_bytes(generador.sintetizar(receta))
            real = hashlib.sha256(wav).hexdigest()
            self.assertEqual(real, receta["wav_sha256"], nombre)
            hashes.add(real)
        self.assertEqual(len(hashes), len(generador.RECETAS))

    def test_pcm_es_mono_44100_sin_clipping_dc_ni_click_de_borde(self):
        self.assertEqual(generador.SAMPLE_RATE, 44_100)
        for nombre, receta in generador.RECETAS.items():
            muestras = generador.sintetizar(receta)
            duracion = len(muestras) / generador.SAMPLE_RATE
            pico = max(abs(muestra) for muestra in muestras) / 32767
            dc = abs(sum(muestras) / len(muestras)) / 32767
            self.assertGreaterEqual(duracion, 0.12, nombre)
            self.assertLessEqual(duracion, 0.30, nombre)
            self.assertLess(pico, 0.90, nombre)
            self.assertLess(dc, 0.01, nombre)
            self.assertEqual(muestras[0], 0, nombre)
            self.assertEqual(muestras[-1], 0, nombre)

    def test_abrir_y_cerrar_tienen_tres_variaciones_distintas(self):
        abrir = [nombre for nombre in generador.RECETAS if nombre.startswith("archivador_abrir_")]
        cerrar = [nombre for nombre in generador.RECETAS if nombre.startswith("archivador_cerrar_")]
        self.assertEqual(len(abrir), 3)
        self.assertEqual(len(cerrar), 3)
        self.assertEqual(len({generador.RECETAS[n]["seed"] for n in abrir}), 3)
        self.assertEqual(len({generador.RECETAS[n]["seed"] for n in cerrar}), 3)


    def test_ogg_runtime_tienen_hash_procedencia_y_presupuesto(self):
        sonido = SONIDO.read_text(encoding="utf-8")
        fichas = {
            ficha["ruta"]: ficha
            for ficha in json.loads(PROCEDENCIA.read_text(encoding="utf-8"))["assets"]
        }
        for nombre, esperado in RUNTIME.items():
            ruta = ASSETS / "audio" / "chip" / nombre
            self.assertTrue(ruta.exists(), nombre)
            self.assertLess(ruta.stat().st_size, 30_000, nombre)
            real = hashlib.sha256(ruta.read_bytes()).hexdigest()
            self.assertEqual(real, esperado, nombre)
            ficha = fichas.get(f"audio/chip/{nombre}")
            self.assertIsNotNone(ficha, nombre)
            self.assertEqual(ficha["sha256"], esperado, nombre)
            self.assertEqual(ficha["autor"], "SIGA-98 · síntesis propia", nombre)
            self.assertEqual(ficha["licencia"], "CC0-1.0", nombre)
            self.assertEqual(ficha["fuente"], "tools/sfx_chip/generar.py", nombre)
            self.assertIn(f"chip/{nombre}", sonido)

    def test_runtime_conserva_kenney_como_fallback(self):
        sonido = SONIDO.read_text(encoding="utf-8")
        self.assertIn("const FAMILIAS_RESPALDO :=", sonido)
        for muestra in (
            "impactMetal_light_000.ogg",
            "impactMetal_light_001.ogg",
            "impactMetal_medium_000.ogg",
            "bookFlip1.ogg",
        ):
            self.assertIn(muestra, sonido)
        self.assertIn("ResourceLoader.exists", sonido)


if __name__ == "__main__":
    unittest.main()
