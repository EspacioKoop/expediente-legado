"""La entrada de Crónicas en OS98 debe funcionar sin otro guardado ni motor."""

from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato

ROOT = Path(__file__).resolve().parents[1]


class CronicasOs98Enlace2589Test(unittest.TestCase):
    def test_sin_progreso_de_campana_ni_handoff_propio(self) -> None:
        fuentes = (
            (ROOT / "godot/guion/cronicas_os98_enlace.gd").read_text(encoding="utf-8")
            + (ROOT / "godot/guion/cronicas_pc_98.gd").read_text(encoding="utf-8")
        )
        self.assertRegex(fuentes, r"EscritorioSigaApp\s*\.\s*new\(")
        self.assertIn("SubViewport.new()", fuentes)
        self.assertIn("own_world_3d = true", fuentes)
        for prohibido in (
            "Partida.guardar(",
            "ClimaxHastur.jugar(",
            "SemillasOniricas.activar_semilla_onirica(",
            "EstadoAplicacionesSiga.guardar(",
            "OS.execute(",
            "HTTPRequest.",
        ):
            self.assertNotIn(prohibido, fuentes)

    def test_os98_abre_minimiza_reanuda_y_cierra(self) -> None:
        comprobar_contrato(
            self,
            "pruebas/pruebas_cronicas_os98_enlace_2589.gd",
            "22 pasadas, 0 fallos",
            timeout=50,
        )
