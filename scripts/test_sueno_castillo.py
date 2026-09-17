from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CASTILLO = RAIZ / "godot" / "guion" / "sueno_castillo.gd"


class SuenoCastilloTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = CASTILLO.read_text(encoding="utf-8")

    def test_runtime_no_depende_de_packs_externos_reservados(self):
        self.assertNotIn("valsekamerplant.itch.io/psx-style-going-medieval", self.texto)
        self.assertNotIn("quaternius.com/packs/fantasypropsmegakit.html", self.texto)
        self.assertNotIn("SELECCION_MINIMA", self.texto)
        self.assertNotIn('"seleccion_onirica"', self.texto)

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
