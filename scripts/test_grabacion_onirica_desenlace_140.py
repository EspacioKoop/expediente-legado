from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
RESOLVER = ROOT / "godot/guion/grabacion_onirica_desenlace.gd"
ESTADO = ROOT / "godot/guion/grabacion_onirica_estado.gd"
CONTROLADOR = ROOT / "godot/guion/dia_sueno_reactivo_app.gd"


class GrabacionOniricaDesenlace140Test(unittest.TestCase):
    def test_regresion_runtime(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_grabacion_onirica_desenlace_140.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)

    def test_costura_consumida_solo_desde_hechos_persistidos(self):
        estado = ESTADO.read_text(encoding="utf-8")
        self.assertIn(
            'var jornada = estado.get("jornada", {})',
            estado,
        )
        self.assertIn(
            'var contexto := {"vuelta_actual": vuelta_actual}',
            estado,
        )
        self.assertIn(
            'GrabacionOniricaDesenlace.resolver(proyeccion, proyeccion["sujeto"], contexto)',
            estado,
        )

        controlador = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn(
            '"vuelta_grabada": maxi(1, int(dia.jornada.get("vuelta", 1)))',
            controlador,
        )

    def test_resolver_es_determinista_y_no_reconsulta_escena(self):
        resolver = RESOLVER.read_text(encoding="utf-8")
        self.assertIn('const ESTADO_BLANCO := "blanco"', resolver)
        self.assertIn('sujeto.get("anomalia_id", "")', resolver)
        self.assertIn('sujeto.get("reactiva", false)', resolver)
        self.assertIn('sujeto.get("vuelta_grabada", null)', resolver)
        self.assertIn('contexto.get("vuelta_actual", null)', resolver)
        self.assertIn("DESENCADENANTE_DEGRADACION_VUELTA", resolver)
        self.assertIn("TYPE_FLOAT", resolver)
        self.assertIn("is_equal_approx(numero, roundf(numero))", resolver)
        for prohibido in (
            "RandomNumberGenerator",
            "randf(",
            "randi(",
            "Partida.",
            "Jornada.",
            "get_node",
            "Camera3D",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, resolver)


if __name__ == "__main__":
    unittest.main()
