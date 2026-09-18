from pathlib import Path
import unittest


CATALOGO = Path("godot/guion/espacios_catalogo.gd")


class TestOficinaZonaClasificacion(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        fuente = CATALOGO.read_text(encoding="utf-8")
        inicio = fuente.index("const OFICINA := {")
        fin = fuente.index("\nconst CALLE := {", inicio)
        cls.oficina = fuente[inicio:fin]

    def test_hay_una_mesa_de_clasificacion_entre_puestos_y_archivo(self):
        self.assertEqual(self.oficina.count('"rol": "mesa_clasificacion"'), 1)
        self.assertIn('"pos": Vector3(3.6, 0.37, 0.0)', self.oficina)
        self.assertIn('"tam": Vector3(1.3, 0.75, 0.9)', self.oficina)

    def test_la_zona_explica_un_flujo_sin_texto_legible(self):
        self.assertEqual(self.oficina.count('"rol": "bandeja_clasificacion"'), 2)
        self.assertEqual(self.oficina.count('"rol": "lote_clasificacion_sin_texto"'), 2)
        inicio = self.oficina.index('"rol": "mesa_clasificacion"')
        fin = self.oficina.index("# La silla 4-B", inicio)
        zona = self.oficina[inicio:fin]
        self.assertNotIn('"texto"', zona)
        self.assertNotIn('"rotulo"', zona)

    def test_no_convierte_la_clasificacion_en_un_quinto_puesto(self):
        for posicion in (
            "Vector3(-4, 0.37, -2)",
            "Vector3(-4, 0.37, 1)",
            "Vector3(1, 0.37, -2)",
            "Vector3(1, 0.37, 1)",
        ):
            self.assertIn(posicion, self.oficina)

        inicio = self.oficina.index('"rol": "mesa_clasificacion"')
        fin = self.oficina.index("# La silla 4-B", inicio)
        zona = self.oficina[inicio:fin]
        self.assertIn('"modelo": "desk"', zona)
        self.assertNotIn('"modelo": "chairDesk"', zona)
        self.assertNotIn('"modelo": "computerScreen"', zona)

    def test_reutiliza_assets_existentes(self):
        inicio = self.oficina.index('"rol": "mesa_clasificacion"')
        fin = self.oficina.index("# La silla 4-B", inicio)
        zona = self.oficina[inicio:fin]
        self.assertNotIn(".glb", zona)
        self.assertNotIn(".png", zona)
        self.assertNotIn(".jpg", zona)


if __name__ == "__main__":
    unittest.main()
