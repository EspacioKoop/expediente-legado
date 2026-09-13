from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
BINGO = ROOT / "godot" / "guion" / "bingo_siga.gd"


class BingoSigaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = BINGO.read_text(encoding="utf-8")

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

    def test_no_hay_recompensas_ni_mutacion_de_partida(self):
        for prohibido in (
            "Partida.guardar",
            'estado["',
            'jornada["dinero"] =',
            'jornada["acciones"] =',
            "pistas_descubiertas.append",
            "vida +=",
        ):
            self.assertNotIn(prohibido, self.codigo)

    def test_no_persistencia_paralela(self):
        for termino in ("racha", "historial", "aceptado", "descartado"):
            self.assertNotIn(f'"{termino}"', self.codigo)


if __name__ == "__main__":
    unittest.main()
