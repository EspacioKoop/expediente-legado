"""Regresión de #133: la casa tiene habitaciones físicas y rincón de TV accesible."""
from pathlib import Path
import re
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
        self.assertIn('"UmbralDormitorio", Vector3(0.0, 0.015, -0.55)', self.hogar)
        self.assertIn('Vector3(1.10, 0.03, 0.18)', self.hogar)

    def test_el_hueco_del_dormitorio_tiene_marco_visual_sin_cambiar_colision(self):
        self.assertIn('const NOMBRE_TRANSICIONES := "TransicionesCasa"', self.hogar)
        self.assertIn('"JambaDormitorioIzquierda"', self.hogar)
        self.assertIn('"JambaDormitorioDerecha"', self.hogar)
        self.assertIn('"MarcoSuperiorDormitorio"', self.hogar)
        self.assertIn("static func _montar_transiciones_domesticas", self.hogar)
        self.assertIn("var malla := MeshInstance3D.new()", self.hogar)
        self.assertIn('"madera_domestica"', self.hogar)

    def test_el_salon_tiene_alfombra_que_agrupa_el_eje_de_ocio(self):
        self.assertIn('ALFOMBRA_SALON_POS := Vector3(-2.10, 0.015, 1.35)', self.hogar)
        self.assertIn('ALFOMBRA_SALON_TAM := Vector3(2.85, 0.03, 1.95)', self.hogar)
        self.assertIn('"AlfombraSalon"', self.hogar)
        self.assertIn('"tejido_domestico"', self.hogar)

    def test_el_armario_esta_en_el_dormitorio_y_no_en_el_salon(self):
        self.assertIn('const ARMARIO := "wardrobe_01"', self.hogar)
        self.assertRegex(
            self.hogar,
            re.compile(
                r'"ArmarioHogar",\s*ARMARIO,\s*Vector3\(-3\.55,\s*0\.0,\s*-2\.45\)'
            ),
        )

    def test_el_rincon_de_television_comparte_eje(self):
        self.assertIn('Vector3(-3.60, 0.0, 1.35)', self.hogar)
        self.assertIn('Vector3(-2.25, 0.0, 1.35)', self.hogar)
        self.assertIn('sofa.position.z = 1.35', self.hogar)

    def test_la_consola_mira_al_interior_y_tiene_objetivo_de_foco_mayor(self):
        self.assertIn('consola.position = Vector3(-3.58, 0.54, 2.10)', self.hogar)
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
