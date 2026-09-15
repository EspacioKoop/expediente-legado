"""Regresión de #133: la casa tiene habitaciones físicas y rincón de TV accesible."""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HOGAR = ROOT / "godot/guion/casa_hogar_cc0.gd"
CONSOLA = ROOT / "godot/guion/consola_sobremesa_98.gd"


class CasaHabitacionesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.hogar = HOGAR.read_text(encoding="utf-8")
        cls.consola = CONSOLA.read_text(encoding="utf-8")

    def test_el_dormitorio_tiene_tabiques_fisicos_y_puerta(self):
        self.assertIn('const NOMBRE_HABITACIONES := "HabitacionesCasa"', self.hogar)
        self.assertIn('"TabiqueDormitorioFrente"', self.hogar)
        self.assertIn('"TabiqueDormitorioLateral"', self.hogar)
        self.assertIn('"DintelDormitorio"', self.hogar)
        self.assertIn("StaticBody3D.new()", self.hogar)
        self.assertIn("CollisionShape3D.new()", self.hogar)
        self.assertIn("BoxShape3D.new()", self.hogar)

    def test_la_puerta_conserva_el_paso_historico_hacia_la_cama(self):
        # Frente hasta x=-0.55 y lateral en x=+0.55: queda 1.10 m de hueco
        # centrado en x=0, el corredor que ya usa el smoke de casa.
        self.assertIn("Vector3(-2.275, ALTO_TABIQUE / 2.0, -0.65)", self.hogar)
        self.assertIn("Vector3(3.45, ALTO_TABIQUE, GROSOR_TABIQUE)", self.hogar)
        self.assertIn("Vector3(0.55, ALTO_TABIQUE / 2.0, -2.075)", self.hogar)
        self.assertIn("Vector3(1.10, 0.80, GROSOR_TABIQUE)", self.hogar)

    def test_el_armario_esta_en_el_dormitorio_y_no_en_el_salon(self):
        self.assertIn('"ArmarioHogar",\n\t\t"wardrobe_01",\n\t\tVector3(-3.55, 0.0, -2.45)', self.hogar)

    def test_el_rincon_de_television_comparte_eje(self):
        self.assertIn('Vector3(-3.60, 0.0, 1.35)', self.hogar)
        self.assertIn('Vector3(-2.25, 0.0, 1.35)', self.hogar)
        self.assertIn('sofa.position.z = 1.35', self.hogar)

    def test_la_consola_mira_al_interior_y_tiene_objetivo_de_foco_mayor(self):
        self.assertIn('consola.position = Vector3(-3.58, 0.54, 1.82)', self.hogar)
        self.assertIn('consola.rotation_degrees.y = -90.0', self.hogar)
        self.assertIn('forma.size = Vector3(0.68, 0.38, 0.52)', self.consola)
        self.assertIn('colision.position = Vector3(0, 0.20, 0)', self.consola)

    def test_no_introduce_texto_ui_economia_ni_estado_nuevo(self):
        combinado = self.hogar + self.consola
        for termino in (
            "Label.new()",
            "RichTextLabel.new()",
            "dinero +=",
            "Partida.guardar",
            "inventario.append",
        ):
            self.assertNotIn(termino, combinado)


if __name__ == "__main__":
    unittest.main()
