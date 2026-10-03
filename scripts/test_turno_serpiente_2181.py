"""Ejecuta el arcade real en proyecto aislado, sin ROMs ni GDExtension."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class TurnoSerpienteTest(unittest.TestCase):
    def test_textos_completos(self):
        textos = json.loads((ROOT / 'godot/datos/turno_serpiente_textos.json').read_text())
        self.assertEqual(set(textos['es']), set(textos['en']))
        self.assertTrue(all(textos['es'].values()))

    def test_arcade_godot(self):
        motor = os.environ.get('GODOT_BIN', 'godot4')
        if not shutil.which(motor):
            self.skipTest('Falta Godot 4.7; definir GODOT_BIN')
        with tempfile.TemporaryDirectory(prefix='siga-serpiente-') as tmp:
            proyecto = Path(tmp)
            (proyecto / 'project.godot').write_text(
                'config_version=5\n[display]\nwindow/size/viewport_width=1920\n'
                'window/size/viewport_height=1080\n[rendering]\n'
                'renderer/rendering_method="gl_compatibility"\n'
            )
            for archivo in ['guion/turno_serpiente.gd', 'guion/turno_serpiente_app.gd',
                            'datos/turno_serpiente_textos.json',
                            'pruebas/pruebas_turno_serpiente_2181.gd']:
                destino = proyecto / archivo
                destino.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / 'godot' / archivo, destino)
            resultado = subprocess.run(
                [motor, '--headless', '--path', tmp, '--script',
                 'pruebas/pruebas_turno_serpiente_2181.gd'],
                capture_output=True, text=True, timeout=60, check=False,
            )
        salida = resultado.stdout + resultado.stderr
        self.assertEqual(resultado.returncode, 0, salida)
        self.assertRegex(salida, r'Turno Serpiente: \d+ pasadas, 0 fallos')
        self.assertNotIn('ERROR:', salida)


if __name__ == '__main__':
    unittest.main()
