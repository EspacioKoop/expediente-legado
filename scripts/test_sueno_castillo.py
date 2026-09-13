from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CASTILLO = RAIZ / "godot" / "guion" / "sueno_castillo.gd"


class SuenoCastilloTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = CASTILLO.read_text(encoding="utf-8")

    def test_registra_las_dos_fuentes_cc0_sin_importar_pack_entero(self):
        self.assertIn("valsekamerplant.itch.io/psx-style-going-medieval", self.texto)
        self.assertIn("quaternius.com/packs/fantasypropsmegakit.html", self.texto)
        self.assertIn('LICENCIA := "CC0-1.0"', self.texto)
        self.assertEqual(self.texto.count('"grupo": "arquitectura"'), 3)
        self.assertEqual(self.texto.count('"grupo": "prop"'), 3)

    def test_selecciona_categorias_confirmadas_y_no_armas_de_relleno(self):
        for categoria in ["building_block", "door", "stairs", "book", "chest", "furniture"]:
            self.assertIn(f'"categoria": "{categoria}"', self.texto)
        self.assertNotIn('"categoria": "weapon"', self.texto)

    def test_reutiliza_la_familia_anular_y_su_malla_poligonal(self):
        self.assertIn("SuenoFamilias.de(SuenoFamilias.ANULAR)", self.texto)
        self.assertIn("SuenoFamilias.malla(SuenoFamilias.ANULAR)", self.texto)
        self.assertIn("SuenoFamilias.valida(SuenoFamilias.ANULAR)", self.texto)
        self.assertNotIn("Rect2i", self.texto)
        self.assertNotIn("BoxMesh", self.texto)

    def test_declara_anomalia_espacial_y_de_objeto_reproducibles(self):
        self.assertIn('"retorno_patio"', self.texto)
        self.assertIn('"codice_desplazado"', self.texto)
        self.assertIn('"vuelta_castillo"', self.texto)
        self.assertIn('"semilla_castillo"', self.texto)
        self.assertIn("posmod(semilla + vuelta, anclas.size())", self.texto)
        for aleatorio in ["randf(", "randi(", "randomize("]:
            self.assertNotIn(aleatorio, self.texto)

    def test_no_invade_estado_jugable(self):
        bloque = self.texto.lower()
        for termino in ["jornada.", "partida", "dinero", "acciones", "veredicto", "pistas_descubiertas"]:
            self.assertNotIn(termino, bloque)


if __name__ == "__main__":
    unittest.main()
