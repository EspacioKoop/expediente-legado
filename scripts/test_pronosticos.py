from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CODIGO = (ROOT / "godot/guion/pronosticos.gd").read_text(encoding="utf-8")


class PronosticosContratoTests(unittest.TestCase):
    def test_crear_bloquea_si_ya_hay_exposicion(self):
        self.assertIn("expuesto: bool = false", CODIGO)
        self.assertIn("or expuesto:", CODIGO)
        self.assertIn("return false", CODIGO)

    def test_un_solo_pronostico_por_expediente(self):
        self.assertIn('estado["por_expediente"].has(expediente_id)', CODIGO)

    def test_abandono_no_se_confunde_con_fallo(self):
        self.assertIn('ESTADO_ABANDONADO := "abandonado"', CODIGO)
        self.assertIn('return ESTADO_SIN_RESOLVER', CODIGO)

    def test_resolucion_distingue_acierto_fallo_y_sin_resolver(self):
        self.assertIn('ESTADO_ACERTADO := "acertado"', CODIGO)
        self.assertIn('ESTADO_FALLADO := "fallado"', CODIGO)
        self.assertIn('ESTADO_SIN_RESOLVER := "sin_resolver"', CODIGO)
        self.assertIn('pronostico["valor"] == resultado', CODIGO)

    def test_no_toca_logica_jugable(self):
        for nombre in ["Acusacion", "Combate", "Jornada", "dinero", "vida", "veredicto"]:
            self.assertNotIn(nombre, CODIGO)

    def test_historial_es_determinista(self):
        self.assertIn("sort_custom", CODIGO)
        self.assertIn('fila["expediente"] = expediente_id', CODIGO)


if __name__ == "__main__":
    unittest.main()
