from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
UTILERIA = ROOT / "godot" / "guion" / "casa_utileria.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_ventana_clima_app.gd"


class VentanaCasaProfundidadTest(unittest.TestCase):
    """Regresión de #566: el ancla histórica (#133) queda embebida en el
    muro trasero de la casa (cara interior en z=-3.4, ancla en z=-3.42), lo
    que oculta tanto el marco como el `Exterior3D` que #572 cuelga de este
    mismo nodo."""

    @classmethod
    def setUpClass(cls):
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")

    def test_la_ventana_se_adelanta_fuera_del_muro(self):
        self.assertIn(
            'ventana.position = pos + Vector3(0, 0, 0.08)',
            self.utileria,
        )

    def test_el_nodo_conserva_el_nombre_que_usa_el_controlador_de_clima(self):
        self.assertIn('ventana.name = "VentanaCasa"', self.utileria)
        self.assertIn('get_node_or_null("VentanaCasa")', self.controlador)

    def test_no_se_reintroduce_un_segundo_pipeline_de_vista_exterior(self):
        # #588 proponía un diorama estático paralelo al Exterior3D dinámico
        # de #572; este fix es solo geométrico y no debe montar otra vista.
        for prohibido in ("VistaExteriorCasa", "PerfilUrbanoCasa", "LucesExteriorCasa"):
            self.assertNotIn(prohibido, self.utileria)


if __name__ == "__main__":
    unittest.main()
