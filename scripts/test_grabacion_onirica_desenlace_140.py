from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
RESOLVER = ROOT / "godot/guion/grabacion_onirica_desenlace.gd"
ESTADO = ROOT / "godot/guion/grabacion_onirica_estado.gd"


class GrabacionOniricaDesenlace140Test(unittest.TestCase):
    def test_regresion_runtime(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_grabacion_onirica_desenlace_140.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)

    def test_costura_consume_sujeto_persistido_sin_reconsultar_escena(self):
        estado = ESTADO.read_text(encoding="utf-8")
        self.assertIn(
            "GrabacionOniricaDesenlace.resolver(proyeccion, proyeccion[\"sujeto\"])",
            estado,
        )
        resolver = RESOLVER.read_text(encoding="utf-8")
        self.assertIn('sujeto.get("anomalia_id", "")', resolver)
        self.assertIn('sujeto.get("reactiva", false)', resolver)
        for prohibido in (
            "RandomNumberGenerator",
            "randf(",
            "randi(",
            "Partida.",
            "Jornada.",
            "get_node",
            "Camera3D",
            "ESTADO_BLANCO",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, resolver)


if __name__ == "__main__":
    unittest.main()
