from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
FORMAS = ROOT / "godot" / "guion" / "sueno_formas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno.gd"
ESCUELA = ROOT / "godot" / "guion" / "sueno_escuela.gd"
ESCUELA_3D = ROOT / "godot" / "guion" / "sueno_escuela_3d.gd"


class SuenoCrucero798Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.formas = FORMAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.escuela = ESCUELA.read_text(encoding="utf-8")
        cls.escuela_3d = ESCUELA_3D.read_text(encoding="utf-8")

    def test_crucero_conserva_id_pero_no_la_cruz_como_forma(self):
        bloque = self.formas.split('\t"crucero":', 1)[1].split('\t"patio":', 1)[0]
        self.assertIn('"familia_poligonal": SuenoFamilias.FRAGMENTADA', bloque)
        self.assertNotIn('Rect2i(0, 5, 22, 6)', bloque)
        self.assertNotIn('Rect2i(8, 0, 6, 16)', bloque)

    def test_runtime_propaga_tabiques_de_la_familia(self):
        self.assertIn(
            'resultado["tabiques_poligonales"] = familia.get("tabiques", []).duplicate(true)',
            self.sueno,
        )

    def test_contenido_conocido_puede_modificar_el_espacio(self):
        self.assertIn('resultado.get("tabiques_poligonales", [])', self.escuela)
        self.assertIn("if not frase_conocida.is_empty():", self.escuela)
        self.assertIn('"desde": Vector2(-5.5, -2.5)', self.escuela)
        self.assertIn('"hasta": Vector2(-5.5 + largo, 0.8)', self.escuela)

    def test_presentacion_escolar_no_redibuja_la_planta_ortogonal(self):
        configurar = self.escuela_3d.split("func _configurar", 1)[1].split(
            "func _process", 1
        )[0]
        self.assertIn('espacio.get("contorno", PackedVector2Array())', configurar)
        self.assertNotIn("_ocultar_arquitectura_base()", configurar)
        self.assertNotIn("_montar_arquitectura(", configurar)


if __name__ == "__main__":
    unittest.main()
