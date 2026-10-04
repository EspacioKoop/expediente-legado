from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot/guion/visor_proyeccion_app.gd"
HELPER = ROOT / "godot/guion/proyeccion_caos_combate_app.gd"


class ProyeccionCaos140Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.helper = HELPER.read_text(encoding="utf-8")

    def test_caos_abre_combate_despues_de_proyeccion(self):
        firma = self.visor.index("if not _guardar_o_avisar():")
        proyeccion = self.visor.index("_reproducir_proyeccion(resultado, estado)", firma)
        fin = self.visor.index("func _al_terminar_proyeccion")
        combate = self.visor.index("_abrir_combate_caos(resultado)", fin)
        self.assertLess(firma, proyeccion)
        self.assertLess(proyeccion, combate)
        self.assertIn("ProyeccionOniricaCinematica.ESTADO_CAOS", self.visor[fin:combate + 200])

    def test_estados_no_caos_convergen_directo_al_sello(self):
        bloque = self.visor[
            self.visor.index("func _al_terminar_proyeccion"):
            self.visor.index("func _abrir_combate_caos")
        ]
        self.assertIn("_reproducir_sello(resultado)", bloque)
        self.assertNotIn("ESTADO_VALIDA", bloque)
        self.assertNotIn("ESTADO_CONTAMINADA", bloque)
        self.assertNotIn("ESTADO_BLANCO", bloque)

    def test_pelea_reutiliza_juicio_y_enjambre(self):
        self.assertIn("JuicioCombate3D.new()", self.helper)
        self.assertIn("JuicioCombateArquetipos.ENJAMBRE", self.helper)
        self.assertIn("combate.configurar(", self.helper)
        self.assertIn("PreferenciasSiga.cargar()", self.helper)
        self.assertIn('"perfil_jugador"', self.helper)
        self.assertIn('"semilla"', self.helper)

    def test_incidente_no_tiene_autoridad_de_campana(self):
        for prohibido in (
            "Partida.",
            "Jornada.",
            "Acusacion.",
            ".guardar(",
            "pistas_descubiertas",
            "dinero",
            "vida",
            "veredicto",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, self.helper)

    def test_ganar_perder_y_abandonar_vuelven_al_mismo_sello(self):
        inicio = self.visor.index("func _al_terminar_combate_caos")
        bloque = self.visor[inicio:]
        self.assertIn("_gano: bool", bloque)
        self.assertIn("_reproducir_sello(resultado)", bloque)
        self.assertNotIn("if _gano", bloque)

        input_inicio = self.visor.index("func _unhandled_input")
        input_bloque = self.visor[input_inicio:inicio]
        self.assertIn('is_action_pressed("cancelar")', input_bloque)
        self.assertIn('is_action_pressed("ui_cancel")', input_bloque)
        self.assertIn("_combate_caos.abandonar()", input_bloque)


if __name__ == "__main__":
    unittest.main()
