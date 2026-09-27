import unittest
from pathlib import Path

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
MARCAS = ROOT / "godot" / "guion" / "marcas.gd"


class CartasOcultasLocaleTest(unittest.TestCase):
    def test_las_ocho_cartas_se_marcan_en_ambos_catalogos(self):
        # 2 cargas + 8 folios x 2 comprobaciones x 2 catálogos + variante vacía.
        comprobar_contrato(
            self,
            "pruebas/pruebas_cartas_ocultas_locale.gd",
            "35 pasadas, 0 fallos",
        )

    def test_marcas_no_fija_la_frase_espanola(self):
        codigo = MARCAS.read_text(encoding="utf-8")
        self.assertIn("CartasOcultas.frase_en_texto(", codigo)
        self.assertNotIn('carta["frase"]', codigo)


if __name__ == "__main__":
    unittest.main()
