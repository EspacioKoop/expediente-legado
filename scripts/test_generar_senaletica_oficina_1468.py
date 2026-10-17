from pathlib import Path
import tempfile
import unittest

from scripts.generar_senaletica_oficina_1468 import ARCHIVOS, comprobar, generar


class TestGenerarSenaleticaOficina1468(unittest.TestCase):
    def test_generar_crea_ficheros_en_directorio_temporal(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir) / "subdirectorio"
            generar(destino)
            for nombre, contenido in ARCHIVOS.items():
                ruta = destino / nombre
                self.assertTrue(ruta.is_file())
                self.assertEqual(ruta.read_text(encoding="utf-8"), contenido)

    def test_comprobar_devuelve_true_tras_generar(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir)
            generar(destino)
            self.assertTrue(comprobar(destino))

    def test_comprobar_devuelve_false_si_falta_un_fichero(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir)
            generar(destino)
            primer_fichero = next(iter(ARCHIVOS.keys()))
            (destino / primer_fichero).unlink()
            self.assertFalse(comprobar(destino))

    def test_comprobar_devuelve_false_si_se_altera_un_fichero(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir)
            generar(destino)
            primer_fichero = next(iter(ARCHIVOS.keys()))
            (destino / primer_fichero).write_text("contenido alterado", encoding="utf-8")
            self.assertFalse(comprobar(destino))

    def test_comprobar_devuelve_false_en_directorio_vacio(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir)
            self.assertFalse(comprobar(destino))


if __name__ == "__main__":
    unittest.main()
