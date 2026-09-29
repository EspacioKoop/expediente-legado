import hashlib
import importlib.util
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GENERADOR = ROOT / "tools" / "sfx_chip" / "generar.py"

spec = importlib.util.spec_from_file_location("sfx_chip_generar", GENERADOR)
generador = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(generador)


class SfxChipGeneradorTest(unittest.TestCase):
    def test_seis_recetas_regeneran_el_pcm_canonico(self):
        self.assertEqual(len(generador.RECETAS), 6)
        hashes = set()
        for nombre, receta in generador.RECETAS.items():
            wav = generador.wav_bytes(generador.sintetizar(receta))
            real = hashlib.sha256(wav).hexdigest()
            self.assertEqual(real, receta["wav_sha256"], nombre)
            hashes.add(real)
        self.assertEqual(len(hashes), 6)

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


if __name__ == "__main__":
    unittest.main()
