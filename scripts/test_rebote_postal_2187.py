"""Contrato ejecutable aislado de ambos arcades y del selector, sin GDExtension."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RebotePostalTest(unittest.TestCase):
    def test_textos_y_selector(self):
        textos = json.loads((ROOT / 'godot/datos/rebote_postal_textos.json').read_text())
        self.assertEqual(set(textos['es']), set(textos['en']))
        self.assertTrue(all(textos['es'].values()))
        consola = (ROOT / 'godot/guion/consola_sobremesa_98.gd').read_text()
        self.assertIn('rebote_solicitado.connect(_abrir_rebote)', consola)
        self.assertIn('menu_solicitado.connect(_volver_selector)', consola)
        self.assertIn('super._alternar(self)', consola)

    def test_partida_godot(self):
        motor = os.environ.get('GODOT_BIN', 'godot4')
        if not shutil.which(motor):
            self.skipTest('Falta Godot 4.7; definir GODOT_BIN')
        with tempfile.TemporaryDirectory(prefix='siga-rebote-') as tmp:
            proyecto = Path(tmp)
            (proyecto / 'project.godot').write_text('config_version=5\n[display]\nwindow/size/viewport_width=1920\nwindow/size/viewport_height=1080\n')
            for nombre in ['guion/rebote_postal.gd', 'guion/rebote_postal_app.gd',
                           'guion/turno_serpiente.gd', 'guion/turno_serpiente_app.gd',
                           'datos/rebote_postal_textos.json', 'datos/turno_serpiente_textos.json',
                           'pruebas/pruebas_rebote_postal_2187.gd']:
                destino = proyecto / nombre
                destino.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / 'godot' / nombre, destino)
            resultado = subprocess.run([motor, '--headless', '--path', tmp, '--script', 'pruebas/pruebas_rebote_postal_2187.gd'], capture_output=True, text=True, timeout=60, check=False)
        salida = resultado.stdout + resultado.stderr
        self.assertEqual(resultado.returncode, 0, salida)
        self.assertRegex(salida, r'Rebote Postal: \d+ pasadas, 0 fallos')
        self.assertNotIn('ERROR:', salida)


if __name__ == '__main__':
    unittest.main()
