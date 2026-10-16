"""Regresión del bug de epígrafes en columna vertical del Beelink (#2596).

Inspección de contrato: NO sustituye comprobar el texto en pantalla a 1080p.
"""
from pathlib import Path
import unittest


SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "godot"
    / "guion"
    / "epigrafes_inicio.gd"
).read_text(encoding="utf-8")


class EpigrafesLegibilidadTest(unittest.TestCase):
    def test_ambos_labels_tienen_ancho_real(self):
        self.assertIn("var ancho_lectura :=", SCRIPT)
        self.assertIn("caja.custom_minimum_size.x = ancho_lectura", SCRIPT)
        self.assertIn("_texto.custom_minimum_size.x = ancho_lectura", SCRIPT)
        self.assertIn("_atribucion.custom_minimum_size.x = ancho_lectura", SCRIPT)

    def test_el_texto_expande_y_no_encoge_a_una_columna(self):
        self.assertIn("_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL", SCRIPT)
        self.assertIn(
            "_atribucion.size_flags_horizontal = Control.SIZE_EXPAND_FILL", SCRIPT
        )
        self.assertNotIn("Control.SIZE_SHRINK_CENTER", SCRIPT)

    def test_conserva_ancho_responsive_y_centrado(self):
        self.assertIn("get_viewport_rect().size.x * 0.82", SCRIPT)
        self.assertIn("1100.0", SCRIPT)
        self.assertIn("CenterContainer.new()", SCRIPT)
        self.assertIn("HORIZONTAL_ALIGNMENT_CENTER", SCRIPT)
        self.assertIn("AUTOWRAP_WORD_SMART", SCRIPT)

    def test_preserva_fade_skip_y_emision_unica(self):
        self.assertIn("func saltar() -> void:", SCRIPT)
        self.assertIn("func _terminar() -> void:", SCRIPT)
        self.assertIn("terminada.emit()", SCRIPT)


if __name__ == "__main__":
    unittest.main()
