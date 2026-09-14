from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
BINGO = ROOT / "godot" / "guion" / "bingo_siga.gd"
JORNADA = ROOT / "godot" / "guion" / "jornada.gd"


class BingoSigaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = BINGO.read_text(encoding="utf-8")
        cls.jornada = JORNADA.read_text(encoding="utf-8")

    def test_generacion_es_determinista_desde_semilla_y_dia(self):
        self.assertIn('Azar.generador(raiz, "dia", [dia, 151])', self.codigo)
        self.assertIn("CANTIDAD_OBJETIVOS := 3", self.codigo)
        self.assertNotIn("randomize()", self.codigo)
        self.assertNotIn("randi()", self.codigo)

    def test_incluye_objetivo_improductivo(self):
        self.assertIn('"tipo": "improductivo"', self.codigo)
        self.assertIn('"terminar_con_dos_acciones"', self.codigo)

    def test_condiciones_se_leen_del_estado_existente(self):
        for campo in (
            'jornada.get("leido_hoy", [])',
            'jornada.get("cerrados_hoy", 0)',
            'jornada.get("acciones", 0)',
            'jornada.get("gato", {})',
            'jornada.get("alquiler", {})',
        ):
            self.assertIn(campo, self.codigo)

    def test_tarjeta_diaria_se_persiste_en_la_jornada(self):
        self.assertIn('const CLAVE_ESTADO := "bingo_siga"', self.codigo)
        self.assertIn('bingo["actual"] = actual', self.codigo)
        self.assertIn('int(actual.get("dia", 0)) != dia', self.codigo)
        self.assertIn('"objetivos": tarjeta(estado)', self.codigo)
        self.assertIn('"bingo_siga": {"actual": {}, "historial": []}', self.jornada)

    def test_decision_es_explicita_y_validada(self):
        for decision in ("aceptar", "descartar", "ignorar"):
            self.assertIn(f'"{decision}"', self.codigo)
        self.assertIn("DECISIONES_VALIDAS.has(decision)", self.codigo)
        self.assertIn('actual["decision"] = decision', self.codigo)

    def test_cierre_congela_completados_antes_del_reset_diario(self):
        self.assertIn("static func cerrar_jornada(jornada: Dictionary)", self.codigo)
        self.assertIn('actual["completados"] = completados', self.codigo)
        self.assertIn('historial.append(actual.duplicate(true))', self.codigo)
        self.assertIn("BingoSiga.cerrar_jornada(jornada)", self.jornada)
        cierre = self.jornada.index("BingoSiga.cerrar_jornada(jornada)")
        sueno = self.jornada.index('jornada["fase"] = "sueño"')
        reset = self.jornada.index('jornada["leido_hoy"] = []', sueno)
        self.assertLess(cierre, sueno)
        self.assertLess(sueno, reset)

    def test_reasignacion_reinicia_bingo_con_la_vida_laboral(self):
        self.assertIn('"bingo_siga": {"actual": {}, "historial": []}', self.jornada)
        self.assertIn("var nueva_vida := nueva(", self.jornada)
        self.assertIn("for clave in nueva_vida:", self.jornada)

    def test_no_hay_recompensas_ni_persistencia_paralela(self):
        for prohibido in (
            "Partida.guardar",
            "FileAccess",
            "store_var",
            "store_string",
            'jornada["dinero"] =',
            'jornada["acciones"] =',
            "pistas_descubiertas.append",
            "vida +=",
        ):
            self.assertNotIn(prohibido, self.codigo)


if __name__ == "__main__":
    unittest.main()
