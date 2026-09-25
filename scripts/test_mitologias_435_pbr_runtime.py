from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot" / "guion"


class Mitologias435PbrRuntimeTest(unittest.TestCase):
    def test_catalogo_carga_los_siete_materiales_mergeados(self):
        texto = (GUION / "mitologias_435_materiales.gd").read_text(encoding="utf-8")
        esperados = (
            "arcilla_uruk",
            "metal_archivo_oxidado",
            "bronce_votivo",
            "escama_hidra",
            "jade_ryu_humedo",
            "caliza_duat",
            "papel_archivo_envejecido",
        )
        for nombre in esperados:
            self.assertIn(f"materiales/{nombre}.tres", texto)
        self.assertIn("base.duplicate()", texto)
        self.assertIn("resource_local_to_scene = true", texto)

    def test_las_seis_familias_consumen_pbr_sin_tocar_su_logica(self):
        contratos = {
            "sueno_gilgamesh.gd": ("arcilla_uruk", "metal_archivo_oxidado"),
            "sueno_minotauro_3d.gd": ("metal_archivo_oxidado", "papel_archivo_envejecido"),
            "sueno_aquiles.gd": ("bronce_votivo", "caliza_duat"),
            "sueno_hidra.gd": ("escama_hidra",),
            "sueno_ryu.gd": ("jade_ryu_humedo", "metal_archivo_oxidado"),
            "sueno_duat.gd": ("caliza_duat", "bronce_votivo"),
        }
        for archivo, materiales in contratos.items():
            texto = (GUION / archivo).read_text(encoding="utf-8")
            self.assertIn("Mitologias435Materiales.crear", texto, archivo)
            for material in materiales:
                self.assertIn(f'"{material}"', texto, archivo)

    def test_fallbacks_procedurales_siguen_presentes(self):
        for archivo in (
            "sueno_gilgamesh.gd",
            "sueno_minotauro_3d.gd",
            "sueno_aquiles.gd",
            "sueno_ryu.gd",
            "sueno_duat.gd",
        ):
            texto = (GUION / archivo).read_text(encoding="utf-8")
            self.assertIn("StandardMaterial3D.new()", texto, archivo)


if __name__ == "__main__":
    unittest.main()
