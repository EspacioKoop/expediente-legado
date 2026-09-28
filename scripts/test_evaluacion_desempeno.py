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
            'jornada.get("trabajillos", {})',
            'trabajillos.get("hechos", 0)',
            'jornada.get(BingoSiga.CLAVE_ESTADO, {})',
            'entrada.get("objetivos", [])',
            'entrada.get("completados", [])',
            'dato.get("tipo", "")',
        ]:
            self.assertIn(token, self.source)

    def test_exposes_independent_categories_without_total_score(self):
        for category in [
            '"productividad"',
            '"precipitacion"',
            '"cuidado_gato"',
            '"liquidez"',
            '"exploracion_onirica"',
            '"dependencia_dinero"',
            '"actividad_improductiva"',
        ]:
            self.assertIn(category, self.source)
        self.assertNotIn('"puntuacion_total"', self.source)
        self.assertNotIn('"nota"', self.source)

    def test_actividad_improductiva_usa_historial_por_vuelta_del_bingo(self):
        self.assertIn('const VERSION_EVALUACION_ACTUAL := 3', self.source)
        self.assertIn(
            'const CATEGORIAS_V2 := CATEGORIAS_V1 + ["dependencia_dinero"]',
            self.source,
        )
        self.assertIn(
            'const CATEGORIAS := CATEGORIAS_V2 + ["actividad_improductiva"]',
            self.source,
        )
        self.assertIn("static func _actividad_improductiva(jornada: Dictionary) -> int:", self.source)
        self.assertIn('String(dato.get("tipo", "")) != "improductivo"', self.source)
        self.assertIn('(completados as Array).has(objetivo_id)', self.source)
        self.assertIn('"actividad_improductiva": _rango(actividad_improductiva, 1, 3)', self.source)

    def test_validacion_mantiene_compatibilidad_v1_v2_y_v3(self):
        self.assertIn("if version_evaluacion == 1:", self.source)
        self.assertIn("requeridas = CATEGORIAS_V1", self.source)
        self.assertIn("elif version_evaluacion == 2:", self.source)
        self.assertIn("requeridas = CATEGORIAS_V2", self.source)
        self.assertIn("version_evaluacion > VERSION_EVALUACION_ACTUAL", self.source)

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
        self.assertIn('"version_evaluacion": VERSION_EVALUACION_ACTUAL', self.source)
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
