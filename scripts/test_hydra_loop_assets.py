from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET


RAIZ = Path(__file__).resolve().parents[1]
HYDRA = RAIZ / "gbc" / "minijuegos" / "hydra_loop"
ASSETS = HYDRA / "assets"
REFERENCIA = HYDRA / "referencia" / "hydra_loop_title_v1.svg"


class HydraLoopAssetsTest(unittest.TestCase):
    def test_tiles_2bpp_caben_en_un_banco(self):
        pares = []
        for indice in range(4):
            texto = (ASSETS / f"title_tiles_{indice:02d}.inc").read_text(encoding="utf-8")
            pares.extend(
                re.findall(r"db\s+\$([0-9A-Fa-f]{2}),\s*\$([0-9A-Fa-f]{2})", texto)
            )

        self.assertEqual(len(pares), 251 * 8)
        self.assertEqual(len(pares) * 2, 251 * 16)

        agregador = (ASSETS / "title_tiles.asm").read_text(encoding="utf-8")
        for indice in range(4):
            self.assertIn(f'INCLUDE "assets/title_tiles_{indice:02d}.inc"', agregador)

    def test_tilemap_es_20_por_18_y_referencia_tiles_validos(self):
        texto = (ASSETS / "title_tilemap.asm").read_text(encoding="utf-8")
        filas = [linea for linea in texto.splitlines() if linea.strip().startswith("db ")]
        self.assertEqual(len(filas), 18)

        indices = []
        for fila in filas:
            valores = [int(valor, 16) for valor in re.findall(r"\$([0-9A-Fa-f]{2})", fila)]
            self.assertEqual(len(valores), 20)
            indices.extend(valores)

        self.assertEqual(len(indices), 20 * 18)
        self.assertEqual(min(indices), 0)
        self.assertEqual(max(indices), 250)
        self.assertTrue(all(indice < 251 for indice in indices))

    def test_paleta_tiene_cuatro_colores_gbc(self):
        texto = (ASSETS / "title_palette.inc").read_text(encoding="utf-8")
        colores = re.findall(r"^\s*dw\s+\$([0-9A-Fa-f]{4})", texto, re.MULTILINE)
        self.assertEqual(len(colores), 4)

    def test_referencia_svg_es_160_por_144(self):
        raiz = ET.parse(REFERENCIA).getroot()
        self.assertEqual(raiz.attrib.get("width"), "160")
        self.assertEqual(raiz.attrib.get("height"), "144")
        self.assertEqual(raiz.attrib.get("viewBox"), "0 0 160 144")


if __name__ == "__main__":
    unittest.main()
