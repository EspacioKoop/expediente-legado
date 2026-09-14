"""Integración real de los pósteres y trazabilidad de los seis binarios."""
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PostersOficinaTest(unittest.TestCase):
    def test_seis_png_con_procedencia_ia_y_hash_real(self):
        registro = json.loads((ROOT / 'godot/assets/procedencia.json').read_text())
        fichas = [f for f in registro['assets'] if f['ruta'].startswith('texturas/poster-1998-')]
        self.assertEqual(len(fichas), 6)
        self.assertEqual(len({f['sha256'] for f in fichas}), 6)
        for ficha in fichas:
            contenido = (ROOT / 'godot/assets' / ficha['ruta']).read_bytes()
            self.assertEqual(contenido[:8], b'\x89PNG\r\n\x1a\n')
            self.assertEqual(hashlib.sha256(contenido).hexdigest(), ficha['sha256'])
            self.assertEqual(ficha['origen'], 'generado_con_IA')
            self.assertNotEqual(ficha['licencia'], 'CC0-1.0')
            x0, y0, x1, y1 = ficha['recorte_px']
            self.assertEqual(struct.unpack('>II', contenido[16:24]), (x1 - x0, y1 - y0))

    def test_escena_real_con_datos_aislados(self):
        with tempfile.TemporaryDirectory(prefix='posters-qa-') as temporal:
            entorno = os.environ.copy()
            entorno['LEGADO_PRUEBAS_AISLADAS'] = '1'
            for variable in ('XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME'):
                entorno[variable] = str(Path(temporal) / variable)
            motor = entorno.get('GODOT_BIN', 'godot4')
            for argumentos in (
                ['--editor', '--import', '--quit'],
                ['--script', 'res://pruebas/pruebas_posters_oficina.gd'],
            ):
                resultado = subprocess.run(
                    [motor, '--headless', '--path', str(ROOT / 'godot'), *argumentos],
                    env=entorno, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, timeout=120, check=False,
                )
                self.assertEqual(resultado.returncode, 0, resultado.stdout)
                self.assertNotRegex(resultado.stdout, r'SCRIPT ERROR:|Parse Error:')
            self.assertNotIn('ERROR:', resultado.stdout)
            resumen = re.search(r'(\d+) pasadas, 0 fallos', resultado.stdout)
            self.assertIsNotNone(resumen, resultado.stdout)
            self.assertGreaterEqual(int(resumen.group(1)), 61)


if __name__ == '__main__':
    unittest.main()
