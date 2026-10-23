"""Prueba del primer cuarto navegable de Crónicas sin modificar la partida (#2589)."""

import unittest
from pathlib import Path

from scripts.godot_pruebas import comprobar_contrato

ROOT = Path(__file__).resolve().parents[1]


class CronicasBastion3DTest(unittest.TestCase):
    def test_sala_no_modifica_sistemas_canonicos(self) -> None:
        fuente = (ROOT / "godot/guion/cronicas_bastion_3d.gd").read_text(encoding="utf-8")
        self.assertIn("ESCENA_CAMINANTE", fuente)
        self.assertIn("JuicioCombate3D.new()", fuente)
        for peligro in ("Partida.guardar(", "ClimaxHastur.jugar(", "SemillasOniricas.activar_semilla_onirica(", "OS.execute(", "HTTPRequest."):
            self.assertNotIn(peligro, fuente)

    def test_sala_ejecutable_en_godot(self) -> None:
        comprobar_contrato(self, "pruebas/pruebas_cronicas_bastion_3d_2589.gd", "41 pasadas, 0 fallos", timeout=60)
