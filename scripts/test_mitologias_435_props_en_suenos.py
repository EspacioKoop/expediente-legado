from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot" / "guion"

CONTRATOS = {
    "sueno_gilgamesh.gd": ("tablilla_uruk", "PropTablillaUruk"),
    "sueno_minotauro_3d.gd": ("archivador_onirico", "PropArchivadorOnirico"),
    "sueno_aquiles.gd": ("panoplia_aquiles", "PropPanopliaAquiles"),
    "sueno_hidra.gd": ("busto_hidra", "PropBustoHidra"),
    "sueno_ryu.gd": ("compuerta_ryu", "PropCompuertaRyu"),
    "sueno_duat.gd": ("legajo_siga", "PropLegajoSiga"),
}


class Mitologias435PropsEnSuenosTest(unittest.TestCase):
    def test_cada_vertical_coloca_un_prop_pbr(self):
        for archivo, (fabrica, nodo) in CONTRATOS.items():
            texto = (GUION / archivo).read_text(encoding="utf-8")
            self.assertIn(f"Mitologias435Props.{fabrica}()", texto, archivo)
            self.assertIn(f'"{nodo}"', texto, archivo)
            self.assertIn('"mitologias_435_solo_visual"', texto, archivo)

    def test_los_props_siguen_sin_colision_ni_input(self):
        texto = (GUION / "mitologias_435_props.gd").read_text(encoding="utf-8")
        for token in ("CollisionShape3D", "StaticBody3D", "CharacterBody3D", "Input.", "Interactuable3D"):
            self.assertNotIn(token, texto)

    def test_duat_no_reemplaza_la_balanza_jugable(self):
        texto = (GUION / "sueno_duat.gd").read_text(encoding="utf-8")
        self.assertIn("_montar_balanza(raiz)", texto)
        self.assertIn('get_node_or_null("Balanza/Brazo")', texto)
        self.assertIn("Mitologias435Props.legajo_siga()", texto)


if __name__ == "__main__":
    unittest.main()
