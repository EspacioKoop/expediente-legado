from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "godot" / "arte" / "mitologias_435"
MATERIALES = (
    "arcilla_uruk",
    "metal_archivo_oxidado",
    "bronce_votivo",
    "escama_hidra",
    "jade_ryu_humedo",
    "caliza_duat",
    "papel_archivo_envejecido",
)


class Mitologias435MaterialesTest(unittest.TestCase):
    def test_cada_material_tiene_triple_mapa_pbr(self):
        for nombre in MATERIALES:
            material = ASSET_ROOT / "materiales" / f"{nombre}.tres"
            self.assertTrue(material.is_file(), nombre)
            texto = material.read_text(encoding="utf-8")
            self.assertIn("roughness_texture", texto)
            self.assertIn("normal_enabled = true", texto)
            self.assertIn("normal_texture", texto)
            for canal in ("albedo", "normal", "roughness"):
                textura = ASSET_ROOT / "texturas" / f"{nombre}_{canal}.svg"
                self.assertTrue(textura.is_file(), f"{nombre}:{canal}")
                svg = textura.read_text(encoding="utf-8")
                self.assertIn('width="512"', svg)
                self.assertIn('height="512"', svg)
                self.assertIn("<pattern", svg)
                self.assertIn(
                    f"res://arte/mitologias_435/texturas/{nombre}_{canal}.svg",
                    texto,
                )

    def test_preview_referencia_toda_la_paleta(self):
        preview = (ASSET_ROOT / "preview_materiales.tscn").read_text(encoding="utf-8")
        for nombre in MATERIALES:
            self.assertIn(f"materiales/{nombre}.tres", preview)

    def test_documenta_procedencia_y_usos_de_las_seis_familias(self):
        doc = (ROOT / "docs" / "assets" / "mitologias-435-pbr.md").read_text(
            encoding="utf-8"
        )
        self.assertIn("Fuentes externas: ninguna", doc)
        self.assertIn("Licencia: MIT", doc)
        for issue in range(436, 442):
            self.assertIn(f"#{issue}", doc)


if __name__ == "__main__":
    unittest.main()
