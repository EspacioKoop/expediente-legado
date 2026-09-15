from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class PresupuestoSigaTest(unittest.TestCase):
    def test_contrato_de_coste_ejecutable_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_presupuesto_siga.gd",
            "12 pasadas, 0 fallos",
        )

    def test_el_visor_consulta_jornada_y_repinta_costes(self):
        codigo = VISOR.read_text(encoding="utf-8")
        self.assertIn("Jornada.coste_lectura", codigo)
        self.assertIn("_refrescar_lista_documentos()", codigo)
        self.assertIn('tr("VISOR_COSTE_REGLA")', codigo)
        self.assertIn('tr("VISOR_COSTE_GRATIS")', codigo)
        self.assertIn('tr("VISOR_COSTE_ACCION")', codigo)
        self.assertIn("Jornada.ACCIONES_POR_DIA", codigo)

    def test_los_rotulos_de_coste_son_traducibles_y_explicitos(self):
        textos = TEXTOS.read_text(encoding="utf-8")
        self.assertIn("VISOR_COSTE_GRATIS,GRATIS", textos)
        self.assertIn("VISOR_COSTE_ACCION,1 acción", textos)
        self.assertIn("VISOR_COSTE_REGLA,", textos)
        self.assertIn("Presupuesto: %d/%d acciones", textos)


if __name__ == "__main__":
    unittest.main()
