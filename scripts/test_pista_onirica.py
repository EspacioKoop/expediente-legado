from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PISTA = ROOT / "godot" / "guion" / "pista_onirica.gd"


class PistaOniricaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = PISTA.read_text(encoding="utf-8")

    def test_solo_recompensa_puzzle_completado(self):
        self.assertIn('resultado_puzzle.get("state", "")', self.codigo)
        self.assertIn('!= "completado"', self.codigo)

    def test_exige_relacion_catalogada_de_dos_origenes(self):
        self.assertIn('pista.has("registroOrigen2")', self.codigo)
        self.assertIn('pista.get("registroOrigen", "")', self.codigo)
        self.assertIn('pista.get("registroOrigen2", "")', self.codigo)

    def test_ambas_fuentes_deben_pertenecer_al_puzzle(self):
        self.assertIn("fuentes.has(a) and fuentes.has(b)", self.codigo)

    def test_no_toca_economia_veredicto_ni_estado_global(self):
        for termino in (
            "dinero",
            "acciones",
            "veredicto",
            "Partida",
            "Jornada",
            "pistas_descubiertas",
        ):
            self.assertNotIn(termino, self.codigo)

    def test_devuelve_identidad_descripcion_y_fuentes_existentes(self):
        self.assertIn('"id": str(pista.get("id", ""))', self.codigo)
        self.assertIn('"descripcion": str(pista.get("descripcion", ""))', self.codigo)
        self.assertIn('"fuentes": [a, b]', self.codigo)


if __name__ == "__main__":
    unittest.main()
