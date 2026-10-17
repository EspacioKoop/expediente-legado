#!/usr/bin/env python3
"""Pruebas unitarias para laboratorio_sonoro_1475.py: escribir_wav, medir_wav, escribir_escucha, medir_ffmpeg."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch
import wave

from scripts.laboratorio_sonoro_1475 import (
    SR,
    escribir_escucha,
    escribir_wav,
    medir_ffmpeg,
    medir_wav,
)


class TestEscribirWav(unittest.TestCase):
    """Pruebas para escribir_wav(ruta: Path, canales: list) -> None."""

    def test_escribir_wav_crea_fichero_valido_mono_y_estereo(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            # Canal mono
            ruta_mono = Path(tmpdir) / "mono.wav"
            escribir_wav(ruta_mono, [[0.0, 0.1, -0.1, 0.5]])
            self.assertTrue(ruta_mono.exists())
            with wave.open(str(ruta_mono), "rb") as w:
                self.assertEqual(w.getnchannels(), 1)
                self.assertEqual(w.getsampwidth(), 2)
                self.assertEqual(w.getframerate(), SR)
                self.assertEqual(w.getnframes(), 4)

            # Canal estéreo
            ruta_estereo = Path(tmpdir) / "estereo.wav"
            escribir_wav(ruta_estereo, [[0.1, -0.1], [0.2, -0.2]])
            self.assertTrue(ruta_estereo.exists())
            with wave.open(str(ruta_estereo), "rb") as w:
                self.assertEqual(w.getnchannels(), 2)
                self.assertEqual(w.getsampwidth(), 2)
                self.assertEqual(w.getframerate(), SR)
                self.assertEqual(w.getnframes(), 2)

    def test_escribir_wav_valida_rango_muestras(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            ruta = Path(tmpdir) / "invalido.wav"
            with self.assertRaises(ValueError):
                escribir_wav(ruta, [[1.0, 0.0]])
            with self.assertRaises(ValueError):
                escribir_wav(ruta, [[-1.0, 0.0]])
            with self.assertRaises(ValueError):
                escribir_wav(ruta, [[float("nan"), 0.0]])


class TestMedirWav(unittest.TestCase):
    """Pruebas para medir_wav(ruta: Path) -> dict."""

    def test_medir_wav_estructura_y_claves(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            ruta = Path(tmpdir) / "prueba.wav"
            escribir_wav(ruta, [[0.0, 0.2, -0.2, 0.0], [0.1, -0.1, 0.1, -0.1]])
            medicion = medir_wav(ruta)

            claves_esperadas = {
                "duracion_s",
                "muestras",
                "canales",
                "pico_dbfs",
                "rms_dbfs",
                "dc_por_canal",
                "clipping",
                "mono_delta_db",
                "salto_extremos",
                "sha256",
            }
            self.assertEqual(set(medicion.keys()), claves_esperadas)
            self.assertEqual(medicion["canales"], 2)
            self.assertEqual(medicion["muestras"], 4)
            self.assertAlmostEqual(medicion["duracion_s"], 4 / SR)
            self.assertEqual(len(medicion["dc_por_canal"]), 2)
            self.assertIsInstance(medicion["sha256"], str)
            self.assertEqual(len(medicion["sha256"]), 64)

    def test_medir_wav_silencio(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            ruta = Path(tmpdir) / "silencio.wav"
            escribir_wav(ruta, [[0.0] * 100])
            medicion = medir_wav(ruta)
            self.assertEqual(medicion["clipping"], 0)
            self.assertEqual(medicion["dc_por_canal"], [0.0])
            self.assertEqual(medicion["pico_dbfs"], -240.0)


class TestIdaYVueltaWav(unittest.TestCase):
    """Prueba de ida y vuelta escribir_wav -> medir_wav."""

    def test_ida_y_vuelta_escribir_medir(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            ruta = Path(tmpdir) / "ida_vuelta.wav"
            canales_orig = [
                [0.0, 0.25, 0.5, 0.25, 0.0, -0.25, -0.5, -0.25],
                [0.1, 0.2, 0.3, 0.2, 0.1, 0.0, -0.1, -0.2],
            ]
            escribir_wav(ruta, canales_orig)

            medicion = medir_wav(ruta)
            self.assertEqual(medicion["canales"], 2)
            self.assertEqual(medicion["muestras"], 8)
            self.assertEqual(medicion["clipping"], 0)
            self.assertGreater(medicion["pico_dbfs"], -10.0)
            self.assertLess(medicion["pico_dbfs"], 0.0)


class TestEscribirEscucha(unittest.TestCase):
    """Pruebas para escribir_escucha(destino: Path, salidas: list[dict], fichas: list[dict]) -> None."""

    def test_escribir_escucha_genera_html_estudio_normal(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir)
            salidas = [
                {"archivo": "oficina_limpio.wav"},
                {"archivo": "oficina_adpcm.wav"},
            ]
            fichas = [
                {"id": "red"},
                {"id": "pulse"},
            ]
            escribir_escucha(destino, salidas, fichas)

            html_file = destino / "escucha.html"
            self.assertTrue(html_file.exists())
            contenido = html_file.read_text(encoding="utf-8")

            self.assertIn("<!doctype html>", contenido)
            self.assertIn("Oficina · machine pulse", contenido)
            self.assertIn('src="oficina_limpio.wav"', contenido)
            self.assertIn('src="oficina_adpcm.wav"', contenido)
            self.assertIn('src="banco/red_limpio.wav"', contenido)
            self.assertIn('src="banco/red_adpcm.wav"', contenido)
            self.assertIn('src="banco/pulse_limpio.wav"', contenido)

    def test_escribir_escucha_genera_html_modo_cata(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir)
            salidas = [
                {"archivo": "m01_t01.wav", "motivo": "m01", "timbre": "t01"},
                {"archivo": "m01_t02.wav", "motivo": "m01", "timbre": "t02"},
            ]
            fichas = [{"id": "sintetico"}]
            escribir_escucha(destino, salidas, fichas)

            html_file = destino / "escucha.html"
            self.assertTrue(html_file.exists())
            contenido = html_file.read_text(encoding="utf-8")

            self.assertIn("Dos motivos · dos timbres", contenido)
            self.assertIn('src="m01_t01.wav"', contenido)
            self.assertIn('src="m01_t02.wav"', contenido)


class TestMedirFfmpeg(unittest.TestCase):
    """Pruebas para medir_ffmpeg(ruta: Path, ejecutable: str) -> dict con subprocess parcheado."""

    @patch("subprocess.run")
    def test_medir_ffmpeg_extrae_true_peak_y_lufs(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(
            stderr=(
                "FFmpeg ebur128 output...\n"
                "Summary:\n"
                "  Integrated loudness:\n"
                "    I:         -21.4 LUFS\n"
                "    Threshold: -31.4 LUFS\n"
                "  True peak:\n"
                "    Peak:       -2.3 dBFS\n"
            ),
            stdout="",
        )

        res = medir_ffmpeg(Path("audio_test.wav"), "ffmpeg")
        self.assertEqual(res, {"true_peak_dbtp": -2.3, "programa_lufs_i": -21.4})

        mock_run.assert_called_once()
        args, kwargs = mock_run.call_args
        cmd = args[0]
        self.assertEqual(cmd[0], "ffmpeg")
        self.assertIn("-hide_banner", cmd)
        self.assertIn("-nostats", cmd)
        self.assertIn("-i", cmd)
        self.assertIn("audio_test.wav", cmd)
        self.assertIn("ebur128=peak=true", cmd)

    @patch("subprocess.run")
    def test_medir_ffmpeg_error_cuando_falta_informacion(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(stderr="Salida sin datos ebur128", stdout="")
        with self.assertRaises(RuntimeError) as ctx:
            medir_ffmpeg(Path("audio_test.wav"), "ffmpeg")
        self.assertIn("FFmpeg no informó true peak/LUFS del programa", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
