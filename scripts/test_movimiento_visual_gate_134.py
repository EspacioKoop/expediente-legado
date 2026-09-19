from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot" / "pruebas" / "capturas_movimiento_134.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "oficina-visual-gate-126.yml"


class MovimientoVisualGate134Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = CAPTURA.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_captura_el_mismo_encuadre_en_dos_momentos(self):
        self.assertIn('"momento-a"', self.captura)
        self.assertIn('"momento-b"', self.captura)
        self.assertIn("const POS_CAMARA", self.captura)
        self.assertIn("const OBJETIVO_CAMARA", self.captura)
        self.assertIn("momento_a.get_data() == momento_b.get_data()", self.captura)

    def test_reutiliza_la_presencia_real_de_companeros(self):
        self.assertIn("CompaneroIdle3D.new()", self.captura)
        self.assertIn("var telefono := indice == 0", self.captura)
        self.assertIn("var trabajo := indice > 0 and indice % 2 == 1", self.captura)
        self.assertIn("var brazos := indice > 0 and not trabajo", self.captura)
        self.assertIn("indice == sitios.size() - 1", self.captura)
        self.assertIn("idle.configurar(", self.captura)

    def test_prueba_visualmente_la_atencion_selectiva(self):
        self.assertIn("ANGULO_ACTOR", self.captura)
        self.assertIn("DISTANCIA_ACTOR", self.captura)
        self.assertIn("giro < deg_to_rad(5.0)", self.captura)
        self.assertIn("_colocar_actor_atencion()", self.captura)
        self.assertIn("_avanzar_idles(PASO_MOMENTO)", self.captura)

    def test_workflow_publica_el_par_para_revision_humana(self):
        self.assertIn("res://pruebas/capturas_movimiento_134.gd", self.workflow)
        self.assertIn("SIGA-98-oficina-movimiento-134-${{ github.sha }}", self.workflow)
        self.assertIn("momento-a.png", self.workflow)
        self.assertIn("momento-b.png", self.workflow)


if __name__ == "__main__":
    unittest.main()
