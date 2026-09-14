from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "evaluacion_desempeno.gd"


class EvaluacionDesempenoContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_uses_existing_partida_and_jornada_state(self):
        for token in [
            'partida.get("jornada", {})',
            'partida.get("veredictos", {})',
            'partida.get("perdio_vida_en_esta_vuelta", false)',
            'jornada.get("mapa", [])',
            'jornada.get("dinero", 0)',
            'gato.get("dias_sin_comer", 0)',
        ]:
            self.assertIn(token, self.source)

    def test_exposes_independent_categories_without_total_score(self):
        for category in [
            '"productividad"',
            '"precipitacion"',
            '"cuidado_gato"',
            '"liquidez"',
            '"exploracion_onirica"',
        ]:
            self.assertIn(category, self.source)
        self.assertNotIn('"puntuacion_total"', self.source)
        self.assertNotIn('"nota"', self.source)

    def test_does_not_mutate_or_grant_rewards(self):
        for forbidden in [
            'partida[',
            'jornada[',
            'Jornada.gastar(',
            'Jornada.gastar_accion(',
            'pistas_descubiertas.append',
        ]:
            self.assertNotIn(forbidden, self.source)


if __name__ == "__main__":
    unittest.main()
