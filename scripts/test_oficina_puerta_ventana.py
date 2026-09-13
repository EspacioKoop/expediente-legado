from pathlib import Path
import unittest


CATALOGO = Path("godot/guion/espacios_catalogo.gd")


class TestOficinaPuertaVentana(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = CATALOGO.read_text(encoding="utf-8")
        inicio = cls.fuente.index("const OFICINA := {")
        fin = cls.fuente.index("\nconst CALLE := {", inicio)
        cls.oficina = cls.fuente[inicio:fin]

    def test_salida_de_oficina_conserva_destino_y_posicion(self):
        self.assertIn(
            '{"pos": Vector3(-6.4, 1.1, 3.5), "destino": "trayecto", "rotulo": "SALIDA_OFICINA"}',
            self.oficina,
        )

    def test_salida_tiene_puerta_fisica_y_marco(self):
        self.assertIn('"rol": "puerta_archivo"', self.oficina)
        self.assertEqual(self.oficina.count('"rol": "marco_puerta_archivo"'), 3)
        self.assertIn('"rol": "manilla_puerta_archivo"', self.oficina)
        self.assertIn('"tam": Vector3(0.12, 2.10, 1.28)', self.oficina)

    def test_ventana_nocturna_sigue_declarada(self):
        self.assertIn('"ventanas":', self.oficina)
        self.assertGreaterEqual(self.oficina.count('Color(0.09, 0.11, 0.20)'), 2)
        self.assertIn('Vector3(-1.5, 1.75, 4.9)', self.oficina)
        self.assertIn('Vector3(2.6, 1.75, 4.9)', self.oficina)

    def test_puerta_no_inventa_texto_narrativo(self):
        inicio = self.oficina.index('"rol": "puerta_archivo"')
        fin = self.oficina.index('"ventanas":', inicio)
        puerta = self.oficina[inicio:fin]
        self.assertNotIn('"texto"', puerta)
        self.assertNotIn('"rotulo"', puerta)


if __name__ == "__main__":
    unittest.main()
