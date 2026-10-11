"""Protege el catálogo y la guarda de literales visibles del panel Entrada49."""
import csv
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / 'godot/guion/entrada49_panel.gd'


class Entrada49TextosTest(unittest.TestCase):
    def test_literales_visibles_respetan_la_guarda_canonica(self):
        patron = re.compile(
            r'(\.text|tooltip_text|placeholder_text)\s*(=|\+=)\s*"[^"\n]*(?<![\\%])[a-zá-úA-ZÁ-Ú]'
        )
        self.assertEqual([], [line.strip() for line in PANEL.read_text().splitlines()
                              if patron.search(line)])

    def test_claves_se_resuelven_sin_cambiar_el_texto_visible(self):
        with (ROOT / 'godot/datos/textos.csv').open(newline='', encoding='utf-8-sig') as f:
            filas = [fila for fila in list(csv.reader(f))[1:] if fila]
        textos = dict(filas)
        esperados = {
            'ENTRADA49_ACCESO': 'Entrada 49',
            'ENTRADA49_TITULO': 'IMPORTACIÓN PATRIMONIAL · ENTRADA 49',
            'ESCRITORIO_CERRAR': 'Cerrar',
        }
        fuente = PANEL.read_text()
        for clave, texto in esperados.items():
            with self.subTest(clave=clave):
                self.assertEqual(1, sum(fila[0] == clave for fila in filas))
                self.assertEqual(texto, textos[clave])
                self.assertRegex(fuente, rf'TranslationServer\s*\.\s*translate\s*\(\s*"{clave}"\s*\)')


if __name__ == '__main__':
    unittest.main()
