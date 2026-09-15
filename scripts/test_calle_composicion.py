from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "calle_composicion.gd"


class CalleComposicionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = CAPA.read_text(encoding="utf-8")

    def test_concentra_seis_pantallas_en_un_lado(self):
        self.assertIn('pantallas.size() != 6', self.codigo)
        self.assertIn('Vector3(-2.56, 1.25 + fila * 0.92', self.codigo)
        self.assertIn('pantallas[i]["giro"] = 90.0', self.codigo)
        self.assertNotIn('giro"] = -90.0', self.codigo)

    def test_el_escaparate_tiene_marco_y_fondo(self):
        self.assertIn("_marco_escaparate()", self.codigo)
        self.assertIn("COLOR_MARCO", self.codigo)
        self.assertIn("COLOR_FONDO", self.codigo)
        self.assertGreaterEqual(self.codigo.count('"tam": Vector3('), 5)

    def test_asigna_medias_lunas_a_las_seis_pantallas(self):
        self.assertIn('pantallas[i]["contenido"] = "media_luna"', self.codigo)
        self.assertNotIn("VideoStream", self.codigo)
        self.assertNotIn("AudioStream", self.codigo)

    def test_no_toca_reglas_de_fase(self):
        for prohibido in (
            '"destino"',
            'SALIDA_PORTAL',
            'Jornada',
            'dinero',
            'acciones',
            'Partida',
        ):
            self.assertNotIn(prohibido, self.codigo)


if __name__ == "__main__":
    unittest.main()
