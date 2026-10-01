from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "godot" / "guion" / "grabacion_onirica_runtime.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"


class GrabacionOniricaRuntime1682Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")

    def test_reutiliza_contratos_sin_adquisicion_ni_autoseleccion(self):
        self.assertIn("GrabacionOniricaMedidor.new()", self.runtime)
        self.assertIn("GrabacionOniricaEstado.registrar_toma(estado, toma)", self.runtime)
        self.assertIn("_sujeto.global_position", self.runtime)
        self.assertIn('_metadatos_sujeto: Dictionary = {}', self.runtime)
        self.assertIn('toma["sujeto"] = _metadatos_sujeto.duplicate(true)', self.runtime)
        self.assertIn('"anomalia_id": anomalia.id_catalogo()', self.controlador)
        self.assertIn('"reactiva": anomalia.reactiva()', self.controlador)
        self.assertIn('get_node_or_null("Camara")', self.controlador)
        self.assertIn('jornada.get("leido_hoy", [])', self.controlador)
        self.assertNotIn("seleccionar_toma", self.runtime)
        self.assertIn(
            "GrabacionOniricaEstado.seleccionar_toma(partida_actual.estado, indice)",
            self.controlador,
        )
        # #1682 sigue sin poseer adquisición: el runtime jamás crea cinta.
        # #140 sí puede iniciarla desde el controller al recoger la cámara física.
        self.assertNotIn("iniciar_cinta", self.runtime)
        self.assertIn("GrabacionOniricaEstado.iniciar_cinta(", self.controlador)

    def test_captura_runtime_en_godot(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_grabacion_onirica_runtime_1682.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)


if __name__ == "__main__":
    unittest.main()
