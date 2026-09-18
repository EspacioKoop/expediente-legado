from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURAR = ROOT / "godot" / "pruebas" / "capturar.gd"
DOC = ROOT / "docs" / "assets" / "tarot-major-arcana.md"


class CapturaTarot645Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.capturar = CAPTURAR.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_busca_el_folio_en_todos_los_expedientes(self) -> None:
        self.assertIn("for i in escena.contenido.casos.size():", self.capturar)
        self.assertIn('registro.get("folio") == folio_carta', self.capturar)
        self.assertIn("escena._al_elegir_caso(indice_caso)", self.capturar)
        self.assertIn('var registros: Array = escena.caso["registros"]', self.capturar)

    def test_no_toca_partida_real_y_permite_reduccion_de_movimiento(self) -> None:
        self.assertIn('OS.get_environment("XDG_DATA_HOME").is_empty()', self.capturar)
        self.assertIn('modo not in ["normal", "reducido"]', self.capturar)
        self.assertIn('preferencias["reduccion_movimiento"] = true', self.capturar)
        self.assertIn("PreferenciasSiga.guardar(preferencias)", self.capturar)

    def test_documenta_las_ocho_cartas_y_no_finge_la_progresion(self) -> None:
        for folio in (
            "ACTA-1999-014",
            "OF-1990-114",
            "MEMO-1993-201",
            "F-1996-00187",
            "ACTA-2007-002",
            "FAX-1996-077",
            "OF-1998-077",
            "ACTA-1998-427B",
        ):
            self.assertIn(folio, self.doc)
        self.assertIn("frontal del plano 2", self.doc)
        self.assertIn("primera pista", self.doc)
        self.assertIn("#1029", self.doc)
        self.assertIn("permanece pendiente", self.doc)


if __name__ == "__main__":
    unittest.main()
