from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "evaluacion_desempeno.gd"
PARTIDA = ROOT / "godot" / "guion" / "partida.gd"
ACUSACION = ROOT / "godot" / "guion" / "acusacion.gd"


class EvaluacionDesempenoContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")
        cls.partida = PARTIDA.read_text(encoding="utf-8")
        cls.acusacion = ACUSACION.read_text(encoding="utf-8")

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

    def test_calcular_remains_pure_and_grants_no_rewards(self):
        calcular = self.source.split("static func calcular", 1)[1].split(
            "static func sellar", 1
        )[0]
        for forbidden in [
            'partida[',
            'jornada[',
            'Jornada.gastar(',
            'Jornada.gastar_accion(',
            'pistas_descubiertas.append',
        ]:
            self.assertNotIn(forbidden, calcular)

    def test_history_is_sealed_idempotently_by_life(self):
        self.assertIn('const CLAVE_HISTORIAL := "evaluaciones_desempeno"', self.source)
        self.assertIn("static func sellar(", self.source)
        self.assertIn("var existente := _registro_de_vuelta(partida, vuelta)", self.source)
        self.assertIn("if not existente.is_empty():", self.source)
        self.assertIn('"veredictos_total": veredictos.size()', self.source)
        self.assertIn('partida[CLAVE_HISTORIAL] = historial', self.source)

    def test_productivity_uses_only_verdicts_from_current_life(self):
        self.assertIn(
            "veredictos.size() - _veredictos_antes_de(partida, vuelta)", self.source
        )
        self.assertIn("int(registro.get(\"veredictos_total\", 0))", self.source)

    def test_partida_persists_and_validates_history_without_version_break(self):
        self.assertIn('"evaluaciones_desempeno": []', self.partida)
        self.assertIn(
            'EvaluacionDesempeno.validar_historial(guardado["evaluaciones_desempeno"])',
            self.partida,
        )
        self.assertIn("const VERSION := 1", self.partida)

    def test_reassignment_seals_before_reset_and_precipitation_sets_real_signal(self):
        sello = 'EvaluacionDesempeno.sellar(estado, "reasignacion", jornada)'
        prometeo = 'Prometeo.reiniciar_vuelta(estado, ajustes(estado)["vidas"])'
        jornada = "Jornada.reiniciar_vuelta(jornada)"
        self.assertIn('estado["perdio_vida_en_esta_vuelta"] = true', self.acusacion)
        self.assertIn(sello, self.acusacion)
        self.assertLess(self.acusacion.index(sello), self.acusacion.index(prometeo))
        self.assertLess(self.acusacion.index(sello), self.acusacion.index(jornada))


if __name__ == "__main__":
    unittest.main()
