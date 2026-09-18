from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
INTERACCION = ROOT / "godot" / "guion" / "gilgamesh_interaccion_3d.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_gilgamesh.gd"
ESCENA = ROOT / "godot" / "escenas" / "sueno_gilgamesh.tscn"


class GilgameshInteraccion3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.interaccion = INTERACCION.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_controller_esta_montado_en_la_escena_standalone(self):
        self.assertIn('path="res://guion/gilgamesh_interaccion_3d.gd"', self.escena)
        self.assertIn('[node name="Interaccion3D" type="Node" parent="."]', self.escena)
        self.assertIn('path="res://guion/sueno_gilgamesh.gd"', self.escena)

    def test_reutiliza_interactuable_3d_sin_sistema_de_input_paralelo(self):
        self.assertIn("Interactuable3D.new()", self.interaccion)
        self.assertIn("CollisionShape3D.new()", self.interaccion)
        self.assertIn("Interactuable3D.Verbo.COGER", self.interaccion)
        self.assertIn("Interactuable3D.Verbo.USAR", self.interaccion)
        self.assertIn("activado.connect(_al_fragmento_activado.bind(fragmento))", self.interaccion)
        self.assertIn("activado.connect(_al_ancla_activada.bind(ancla_id))", self.interaccion)
        self.assertNotIn("Input.", self.interaccion)
        self.assertNotIn("CanvasLayer", self.interaccion)

    def test_seleccionar_fragmento_y_ancla_usa_el_contrato_existente(self):
        self.assertIn('_fragmento_seleccionado = fragmento', self.interaccion)
        self.assertRegex(
            self.interaccion,
            r"sueno\s*\.\s*colocar_fragmento\s*\(",
        )
        self.assertIn("seleccionado,", self.interaccion)
        self.assertIn("ancla_id,", self.interaccion)
        self.assertIn("_reduccion_movimiento,", self.interaccion)

    def test_fallo_es_reversible_y_conserva_la_pieza_seleccionada(self):
        fallo = self.interaccion.split('if not bool(resultado["aceptada"]):', 1)[1]
        fallo = fallo.split("_deshabilitar(", 1)[0]
        self.assertIn("_actualizar_feedback_seleccion(sueno)", fallo)
        self.assertIn("return", fallo)
        self.assertNotIn('_fragmento_seleccionado = ""', fallo)

    def test_acierto_desactiva_solo_la_pieza_y_ancla_resueltas(self):
        self.assertIn("_fragmentos_interactivos.get(seleccionado)", self.interaccion)
        self.assertIn("_anclas_interactivas.get(ancla_id)", self.interaccion)
        self.assertIn("zona.habilitado = false", self.interaccion)
        self.assertIn('_fragmento_seleccionado = ""', self.interaccion)

    def test_fragmentos_y_anclas_usan_las_laminas_propias(self):
        for motivo in ("puerta", "sello", "ola", "archivo"):
            ruta = f'res://arte/gilgamesh/fragmento_{motivo}.svg'
            self.assertIn(ruta, self.sueno)
        self.assertIn("_montar_motivo_visual(pieza, fragmento, tam)", self.sueno)
        self.assertIn(
            "_montar_motivo_visual(ancla, fragmento, tam_ancla, true)",
            self.sueno,
        )
        self.assertIn('lamina.name = "MotivoVisual"', self.sueno)
        self.assertNotIn("gilgamesh_arte_preview.tscn", self.sueno)

    def test_reduccion_movimiento_viene_de_preferencias(self):
        self.assertIn("PreferenciasSiga.cargar()", self.interaccion)
        self.assertIn('get("reduccion_movimiento", false)', self.interaccion)


if __name__ == "__main__":
    unittest.main()
