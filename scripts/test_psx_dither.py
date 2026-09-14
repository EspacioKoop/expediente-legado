from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SHADER = ROOT / "godot" / "arte" / "psx.gdshader"


def bayer_2x2(x: int, y: int) -> int:
    matriz = ((0, 2), (3, 1))
    return matriz[y % 2][x % 2]


def bayer_4x4(x: int, y: int) -> int:
    menor = bayer_2x2(x, y)
    mayor = bayer_2x2(x // 2, y // 2)
    return menor * 4 + mayor


class PsxDitherTest(unittest.TestCase):
    def test_bayer_4x4_reparte_los_16_niveles(self):
        valores = [bayer_4x4(x, y) for y in range(4) for x in range(4)]
        self.assertEqual(sorted(valores), list(range(16)))

    def test_dithering_vive_en_el_material_3d_y_no_en_la_interfaz(self):
        texto = SHADER.read_text(encoding="utf-8")
        self.assertIn("shader_type spatial;", texto)
        self.assertIn("uniform float dithering", texto)
        self.assertIn("bayer_4x4(FRAGCOORD.xy)", texto)
        self.assertNotIn("shader_type canvas_item", texto)
        self.assertNotIn("hint_screen_texture", texto)

    def test_dithering_se_puede_apagar_y_respeta_la_cuantizacion(self):
        texto = SHADER.read_text(encoding="utf-8")
        self.assertIn("* dithering / niveles", texto)
        self.assertIn("floor(color * niveles) / niveles", texto)
        self.assertIn("max(tonos, 1.0)", texto)


if __name__ == "__main__":
    unittest.main()
