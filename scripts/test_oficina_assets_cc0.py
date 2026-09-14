"""Importación binaria CC0 y montaje real sin modificar la física."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class OficinaAssetsCc0Test(unittest.TestCase):
    def test_nueve_glb_originales_autocontenidos(self):
        fichas = json.loads((ROOT / 'godot/assets/procedencia.json').read_text())['assets']
        fichas = [f for f in fichas if f['ruta'].startswith('modelos/oficina_psx/') and f['ruta'].endswith('.glb')]
        self.assertEqual(len(fichas), 9)
        for ficha in fichas:
            contenido = (ROOT / 'godot/assets' / ficha['ruta']).read_bytes()
            self.assertEqual(contenido[:4], b'glTF')
            self.assertEqual(hashlib.sha256(contenido).hexdigest(), ficha['sha256'])
            self.assertEqual(ficha['licencia'], 'CC0-1.0')
            largo = int.from_bytes(contenido[12:16], 'little')
            gltf = json.loads(contenido[20:20 + largo])
            for imagen in gltf.get('images', []):
                self.assertNotIn('uri', imagen, 'GLB debe llevar sus texturas incorporadas')

    def test_montaje_real(self):
        with tempfile.TemporaryDirectory(prefix='cc0-qa-') as temporal:
            env = os.environ.copy()
            env['LEGADO_PRUEBAS_AISLADAS'] = '1'
            for var in ('XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME'):
                env[var] = str(Path(temporal) / var)
            motor = env.get('GODOT_BIN', 'godot4')
            for args in (['--editor', '--import', '--quit'],
                         ['--script', 'res://pruebas/pruebas_oficina_assets_cc0.gd']):
                r = subprocess.run([motor, '--headless', '--path', str(ROOT / 'godot'), *args],
                                   env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, timeout=120, check=False)
                self.assertEqual(r.returncode, 0, r.stdout)
                self.assertNotRegex(r.stdout, r'SCRIPT ERROR:|Parse Error:')
            self.assertNotIn('ERROR:', r.stdout)
            self.assertRegex(r.stdout, r'\d+ pasadas, 0 fallos')
