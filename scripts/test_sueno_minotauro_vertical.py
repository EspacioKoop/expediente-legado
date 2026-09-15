from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
VIGILIA = RAIZ / "godot" / "guion" / "minotauro_vigilia.gd"
SUENO = RAIZ / "godot" / "guion" / "sueno_minotauro.gd"


class MinotauroVerticalTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")

    def test_vigilia_requiere_interaccion_deliberada_fuera_de_oficina(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn('const FUENTE := "rom:ariadna_labertinto_98"', self.vigilia)
        self.assertIn("const INTERACCIONES_REQUERIDAS := 2", self.vigilia)
        self.assertIn("_interacciones < INTERACCIONES_REQUERIDAS", self.vigilia)
        self.assertIn("SemillasOniricas.activar_semilla_onirica", self.vigilia)

    def test_fuente_es_estable_y_semilla_canonica(self):
        self.assertIn('const ID_MITO := "minotauro"', self.vigilia)
        self.assertIn("semilla_onirica_minotauro", self.sueno)
        self.assertIn('"minotauro"', (RAIZ / "godot" / "guion" / "SemillasOniricas.gd").read_text(encoding="utf-8"))

    def test_no_hay_activacion_por_presencia_o_una_sola_interaccion(self):
        codigo = re.sub(r"#.*", "", self.vigilia)
        self.assertIn("if _activada or _jornada.is_empty()", codigo)
        self.assertIn("if _interacciones < INTERACCIONES_REQUERIDAS", codigo)
        self.assertEqual(codigo.count("activar_semilla_onirica"), 1)

    def test_familia_sigue_fuera_de_pool_sin_semilla(self):
        self.assertIn("static func habilitada(semillas: Dictionary)", self.sueno)
        semillas = (RAIZ / "godot" / "guion" / "SemillasOniricas.gd").read_text(encoding="utf-8")
        self.assertIn("static func familias_activas(jornada: Dictionary)", semillas)
        self.assertIn('"minotauro"', semillas)


if __name__ == "__main__":
    unittest.main()
