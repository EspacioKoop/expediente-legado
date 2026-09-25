from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
EFECTO = ROOT / "godot/guion/texto_corrupto_narrativo.gd"
CONTAMINACION = ROOT / "godot/guion/contaminacion_os98.gd"
SMOKE = ROOT / "godot/pruebas/issue_806_smoke.gd"


class TextoCorrupto806Test(unittest.TestCase):
    def test_motor_es_determinista_y_reutilizable(self):
        fuente = EFECTO.read_text(encoding="utf-8")
        self.assertIn("class_name TextoCorruptoNarrativo", fuente)
        self.assertIn("func resolver_texto", fuente)
        self.assertIn("func progreso_para_tiempo", fuente)
        self.assertIn("nodo is Label", fuente)
        self.assertIn("nodo is RichTextLabel", fuente)
        self.assertIn("nodo is Label3D", fuente)
        self.assertNotIn("RandomNumberGenerator", fuente)
        self.assertNotIn("randf(", fuente)

    def test_accesibilidad_y_alternativa_legible(self):
        fuente = EFECTO.read_text(encoding="utf-8")
        self.assertIn("reducir_movimiento", fuente)
        self.assertIn("critico", fuente)
        self.assertIn('"texto_legible": texto', fuente)

    def test_contaminacion_publica_configuracion_data_driven(self):
        fuente = CONTAMINACION.read_text(encoding="utf-8")
        self.assertIn('"efecto_texto"', fuente)
        self.assertIn('"semilla"', fuente)
        self.assertIn('"intensidad"', fuente)
        self.assertIn('"duracion"', fuente)

    def test_smoke_cubre_documento_y_rotulo_3d(self):
        fuente = SMOKE.read_text(encoding="utf-8")
        self.assertIn("RichTextLabel.new()", fuente)
        self.assertIn("Label3D.new()", fuente)
        self.assertIn("progresión animada reversible", fuente)


if __name__ == "__main__":
    unittest.main()
