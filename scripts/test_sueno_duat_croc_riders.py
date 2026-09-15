from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
ECO = RAIZ / "godot" / "guion" / "sueno_duat_croc_riders.gd"


class SuenoDuatCrocRidersTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = ECO.read_text(encoding="utf-8")

    def test_relacion_es_presentacional_y_no_desbloquea_duat(self):
        self.assertIn('const ROM_ID := "croc_riders_98"', self.texto)
        self.assertIn('const RELACION := "eco_visual"', self.texto)
        self.assertIn('"desbloquea_duat": false', self.texto)
        self.assertIn('"modifica_estado_rom": false', self.texto)
        self.assertIn('"modifica_campana": false', self.texto)

    def test_no_toca_estado_de_campana_ni_semillas(self):
        for termino in [
            "SemillasOniricas.",
            "activar_semilla_onirica(",
            "Partida.",
            "Jornada.",
            "inventario[",
            "pistas[",
        ]:
            self.assertNotIn(termino, self.texto)

    def test_relieve_es_procedural_y_usa_cuatro_tonos(self):
        self.assertIn("const RELIEVE := [", self.texto)
        self.assertIn("QuadMesh.new()", self.texto)
        self.assertIn("BaseMaterial3D.SHADING_MODE_UNSHADED", self.texto)
        for color in ["COLOR_0", "COLOR_1", "COLOR_2", "COLOR_3"]:
            self.assertIn(f"const {color} := Color(", self.texto)
        for motivo in ["cocodrilo", "piramide", "nilo", "paleta_gbc_4"]:
            self.assertIn(f'"{motivo}"', self.texto)

    def test_acople_es_idempotente_y_no_anima_el_panel(self):
        self.assertIn("static func acoplar_a_duat(", self.texto)
        self.assertIn('raiz.get_node_or_null("EcoCrocRiders98")', self.texto)
        self.assertIn('panel.name = "EcoCrocRiders98"', self.texto)
        self.assertNotIn("create_tween(", self.texto)
        self.assertNotIn("AnimationPlayer", self.texto)


if __name__ == "__main__":
    unittest.main()
