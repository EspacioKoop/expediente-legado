"""Regresiones de señal, codec, partitura y export; no certifican escucha."""
import copy
import importlib.util
import json
from html.parser import HTMLParser
import math
from pathlib import Path
import shutil
import tempfile
import unittest
import wave

RUTA = Path(__file__).with_name("laboratorio_sonoro_1475.py")
SPEC = importlib.util.spec_from_file_location("laboratorio_sonoro_1475", RUTA)
LAB = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LAB)


class CodecTest(unittest.TestCase):
    def test_vector_nibbles_firmados_y_orden(self):
        bloque = bytes([0, 1, 0x78, 0xF1] + [0] * 12)
        self.assertEqual(LAB.decodificar_adpcm(bloque)[:4], [-32768, 28672, 4096, -4096])

    def test_vector_predictor_y_historial_entre_bloques(self):
        bloque = bytes([0x1C, 0] + [0x11] * 14)
        salida = LAB.decodificar_adpcm(bloque + bytes([0x1C, 1] + [0] * 14))
        self.assertEqual(salida[:8], list(range(1, 9)))
        self.assertGreater(salida[28], 0)

    def test_silencio_exactitud_y_flags(self):
        datos = LAB.codificar_adpcm([0] * 56, bucle=True)
        self.assertEqual(len(datos), 32)
        self.assertEqual(datos[1], 4)
        self.assertEqual(datos[17], 3)
        self.assertEqual(LAB.decodificar_adpcm(datos), [0] * 56)

    def test_senal_error_y_repeticion(self):
        pcm = [round(15000 * math.sin(math.tau * 220 * i / LAB.SR)) for i in range(2800)]
        datos = LAB.codificar_adpcm(pcm)
        recuperado = LAB.decodificar_adpcm(datos)
        rms_error = math.sqrt(sum((a - b) ** 2 for a, b in zip(pcm, recuperado)) / len(pcm))
        self.assertLess(rms_error, 100)
        self.assertEqual(datos, LAB.codificar_adpcm(pcm))
        self.assertEqual(datos[-15], 1)

    def test_rechaza_bloques_invalidos_y_pcm_fuera_rango(self):
        for datos in (b"", b"\0" * 15, bytes([0x50] + [0] * 15), bytes([0x0D] + [0] * 15)):
            with self.subTest(datos=datos), self.assertRaises(ValueError):
                LAB.decodificar_adpcm(datos)
        with self.assertRaises(ValueError):
            LAB.codificar_adpcm([32768])
        for valores in ([1.0], [float("nan")], [float("inf")]):
            with self.assertRaises(ValueError):
                LAB.pcm16(valores)


class PartituraTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg = json.loads(LAB.RECETA.read_text())
        cls.banco = {k: LAB.sintetizar(v) for k, v in cls.cfg["banco"].items()}

    def test_semilla_fuente_y_reutilizacion(self):
        receta = self.cfg["banco"]["tecla"]
        self.assertEqual(self.banco["tecla"], LAB.sintetizar(receta))
        otra = dict(receta, semilla=12)
        self.assertNotEqual(self.banco["tecla"], LAB.sintetizar(otra))
        eventos = LAB.eventos(self.cfg, self.banco)
        self.assertGreater(len(eventos), 40)
        self.assertLessEqual(LAB.contar_voces(eventos), 24)

    def test_delay_offset_y_retrigger_en_tiempo_real(self):
        cfg = copy.deepcopy(self.cfg)
        cfg["orden"] = ["respuesta"]
        notas = LAB.eventos(cfg, self.banco)
        self.assertEqual(notas[3]["offset"], 280)
        self.assertEqual(notas[-1]["inicio"], round((0.5 + (14 * 6 + 3) * 2.5 / 96) * LAB.SR))
        cfg["orden"] = ["tension"]
        notas = [e for e in LAB.eventos(cfg, self.banco) if e["instrumento"] == "tecla"]
        self.assertEqual(len(notas), 9)
        self.assertLessEqual(notas[-1]["muestras"], round(2.5 / 96 * LAB.SR))

    def test_voces_cuentan_colas_y_final_antes_de_inicio(self):
        self.assertEqual(LAB.contar_voces([dict(inicio=0, muestras=10), dict(inicio=5, muestras=10)]), 2)
        self.assertEqual(LAB.contar_voces([dict(inicio=0, muestras=10), dict(inicio=10, muestras=10)]), 1)

    def test_limites_pitch_offset_y_duracion(self):
        for clave, valor in (("semitonos", 13), ("offset", 999999), ("duracion_filas", 0), ("retrigger_ticks", 0)):
            cfg = copy.deepcopy(self.cfg)
            cfg["patrones"]["aire"][0][clave] = valor
            with self.subTest(clave=clave), self.assertRaises(ValueError):
                LAB.eventos(cfg, self.banco)
        with self.assertRaises(ValueError):
            LAB.mezclar(self.banco, [dict(instrumento="red", pan=0, ganancia=1,
                        inicio=90, muestras=20, offset=0, ratio=1, bucle=True)], 100)

    def test_mezcla_determinista_y_mono(self):
        notas = [dict(instrumento="red", pan=0, ganancia=0.2, inicio=100,
                      muestras=8000, offset=0, ratio=1, bucle=True)]
        a = LAB.mezclar(self.banco, notas, 16000)
        self.assertEqual(a, LAB.mezclar(self.banco, notas, 16000))
        self.assertTrue(all(abs(l - r) < 1e-15 for l, r in zip(*a)))


class ExportTest(unittest.TestCase):
    def test_presupuestos_rechazados_antes_de_escribir(self):
        for campo, limite in (("max_voces", 1), ("max_banco_adpcm_bytes", 16)):
            with self.subTest(campo=campo), tempfile.TemporaryDirectory() as temporal:
                cfg = json.loads(LAB.RECETA.read_text())
                cfg[campo] = limite
                receta = Path(temporal) / "receta.json"
                receta.write_text(json.dumps(cfg))
                destino = Path(temporal) / "salida"
                with self.assertRaisesRegex(ValueError, "presupuesto"):
                    LAB.generar(receta, destino)
                self.assertFalse(destino.exists())

    def test_estudio_real_manifest_banco_y_cata(self):
        with tempfile.TemporaryDirectory() as temporal:
            destino = Path(temporal)
            manifest = LAB.generar(LAB.RECETA, destino)
            self.assertEqual(manifest["escucha_humana"], "pendiente")
            self.assertEqual(len(manifest["banco"]), 4)
            self.assertLessEqual(manifest["banco_adpcm_bytes"], 32768)
            hashes = []
            for render in manifest["renders"]:
                ruta = destino / render["archivo"]
                self.assertEqual(render["sha256"], LAB.sha256(ruta.read_bytes()))
                self.assertEqual(render["duracion_s"], 28)
                self.assertEqual(render["clipping"], 0)
                self.assertLessEqual(render["pico_dbfs"], -8.99)
                self.assertLess(max(map(abs, render["dc_por_canal"])), 0.0001)
                self.assertGreater(render["mono_delta_db"], -0.5)
                with wave.open(str(ruta)) as wav:
                    self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate()), (2, 2, 44100))
                hashes.append(render["sha256"])
            self.assertNotEqual(*hashes)
            for ficha in manifest["banco"]:
                spu = destino / "banco" / (ficha["id"] + ".spu")
                self.assertEqual(ficha["sha256_adpcm"], LAB.sha256(spu.read_bytes()))
            self.assertTrue((destino / "REVISION.md").is_file())
            self.assertEqual(json.loads((destino / "manifest.json").read_text()), manifest)
            self.assertTrue((destino / "cata.m3u").read_text().startswith("#EXTM3U\n"))
            audios = []

            class Reproductores(HTMLParser):
                def handle_starttag(self, tag, attrs):
                    if tag == "audio":
                        audios.append(dict(attrs))

            Reproductores().feed((destino / "escucha.html").read_text(encoding="utf-8"))
            self.assertEqual({a["src"] for a in audios},
                             {p.relative_to(destino).as_posix() for p in destino.rglob("*.wav")})
            self.assertEqual(len(audios), 10)
            for audio in audios:
                self.assertIn("controls", audio)
                self.assertNotIn("autoplay", audio)


@unittest.skipUnless(shutil.which("ffmpeg"), "La cata calibrada exige FFmpeg; su workflow lo instala")
class CataCompositivaTest(unittest.TestCase):
    def test_cuatro_cruces_pcm_y_calibracion_por_timbre(self):
        with tempfile.TemporaryDirectory() as temporal:
            destino = Path(temporal)
            manifest = LAB.generar_cata(LAB.RECETA_CATA, destino)
            self.assertEqual(manifest["voces_maximas"], 1)
            self.assertEqual(manifest["banco_pcm_bytes"], 112896)
            self.assertEqual(manifest["escucha_humana"], "pendiente")
            self.assertEqual({(r["motivo"], r["timbre"]) for r in manifest["renders"]},
                             {(m, t) for m in ("m01", "m02") for t in ("t01", "t02")})
            niveles = [x["lufs_despues"] for x in manifest["calibracion"].values()]
            self.assertLessEqual(max(niveles) - min(niveles), 0.5)
            self.assertEqual(len({r["sha256"] for r in manifest["renders"]}), 4)
            for r in manifest["renders"]:
                self.assertEqual(r["duracion_s"], 10)
                self.assertEqual(r["clipping"], 0)
                self.assertLessEqual(r["true_peak_dbtp"], -6)
                self.assertEqual(r["sha256"], LAB.sha256((destino / r["archivo"]).read_bytes()))
                with wave.open(str(destino / r["archivo"])) as wav:
                    self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate()), (2, 2, 44100))
                    self.assertEqual(set(wav.readframes(22050)), {0})
            partitura = json.loads((destino / "partitura.json").read_text())
            self.assertEqual([len(p) for p in partitura.values()], [6, 8])
            for notas in partitura.values():
                self.assertEqual({e["muestras"] for e in notas}, {11025})
                self.assertEqual(notas[0]["inicio"], 22050)
            audios = []

            class Reproductores(HTMLParser):
                def handle_starttag(self, tag, attrs):
                    if tag == "audio":
                        audios.append(dict(attrs))

            Reproductores().feed((destino / "escucha.html").read_text(encoding="utf-8"))
            self.assertEqual({a["src"] for a in audios}, {r["archivo"] for r in manifest["renders"]})
            self.assertEqual(len(audios), 4)
            self.assertTrue(all("controls" in a and "autoplay" not in a for a in audios))

    def test_rechaza_duracion_de_timbre_distinta_y_solapamiento(self):
        for cambio in ("duracion", "solapamiento"):
            with self.subTest(cambio=cambio), tempfile.TemporaryDirectory() as temporal:
                cfg = json.loads(LAB.RECETA_CATA.read_text())
                if cambio == "duracion":
                    cfg["timbres"]["t02"]["muestras"] = 14112
                else:
                    cfg["motivos"]["m01"]["filas"] = [0, 1, 6]
                receta = Path(temporal) / "receta.json"
                receta.write_text(json.dumps(cfg))
                destino = Path(temporal) / "salida"
                with self.assertRaises(ValueError):
                    LAB.generar_cata(receta, destino)
                self.assertFalse(destino.exists())


class CareoTrackerTest(unittest.TestCase):
    def test_render_determinista_manifest_y_presupuesto(self):
        with tempfile.TemporaryDirectory() as temporal:
            raiz = Path(temporal)
            destino_a = raiz / "a"
            destino_b = raiz / "b"

            manifest_a = LAB.generar_careo_tracker(destino_a)
            manifest_b = LAB.generar_careo_tracker(destino_b)

            self.assertEqual(manifest_a, manifest_b)
            self.assertEqual(manifest_a["estudio"], "careo_tracker")
            self.assertEqual(manifest_a["escucha_humana"], "pendiente")
            self.assertEqual(manifest_a["duracion_s"], 8)
            self.assertEqual(manifest_a["frecuencia_hz"], 44100)
            self.assertLessEqual(manifest_a["voces_maximas"], manifest_a["limite_voces"])
            self.assertLessEqual(len(manifest_a["banco"]), manifest_a["banco_pequeno_max_fuentes"])

            wav_a = destino_a / "careo_tracker.wav"
            wav_b = destino_b / "careo_tracker.wav"
            self.assertEqual(wav_a.read_bytes(), wav_b.read_bytes())
            self.assertEqual(
                manifest_a["renders"][0]["sha256"],
                LAB.sha256(wav_a.read_bytes()),
            )
            self.assertEqual(
                (destino_a / "manifest.json").read_bytes(),
                (destino_b / "manifest.json").read_bytes(),
            )
            self.assertEqual(
                (destino_a / "partitura.json").read_bytes(),
                (destino_b / "partitura.json").read_bytes(),
            )

            bucle = manifest_a["bucle"]
            self.assertEqual(bucle["inicio_muestras"], 0)
            self.assertEqual(bucle["fin_muestras"], 8 * LAB.SR)
            self.assertEqual(bucle["inicio_s"], 0)
            self.assertEqual(bucle["fin_s"], 8)

            render = manifest_a["renders"][0]
            self.assertEqual(render["clipping"], 0)
            self.assertLess(max(map(abs, render["dc_por_canal"])), 0.0001)
            self.assertLessEqual(render["pico_dbfs"], -8.99)

    def test_no_escribe_en_runtime_y_no_lee_samples_externos(self):
        runtime = LAB.RAIZ / "godot" / "careo_tracker_test"
        with self.assertRaisesRegex(ValueError, "no escribe dentro del runtime"):
            LAB.generar_careo_tracker(runtime)

        fuente = Path(LAB.__file__).read_text(encoding="utf-8")
        inicio = fuente.index("def generar_careo_tracker(")
        fin = fuente.index("\ndef main()", inicio)
        bloque = fuente[inicio:fin]
        for prohibido in (
            "requests",
            "urllib",
            "urlopen",
            "AudioStream",
            "godot/assets",
            "referencia/audio/",
            "samples/",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, bloque)


if __name__ == "__main__":
    unittest.main()
