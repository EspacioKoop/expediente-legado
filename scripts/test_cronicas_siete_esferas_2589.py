"""Regresiones de Crónicas: fuente canónica y montaje sin dobles estados (#2589)."""

import unittest
from pathlib import Path

from scripts.godot_pruebas import comprobar_contrato

RAIZ = Path(__file__).resolve().parents[1]
ADAPTADOR = RAIZ / "godot/guion/cronicas_siete_esferas_montaje.gd"


class CronicasSieteEsferas2589Test(unittest.TestCase):
    def test_adaptador_no_reemplaza_dueno_del_climax(self) -> None:
        guion = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn("ClimaxHastur.estado_actual(", guion)
        self.assertIn("ClimaxHastur.clave_vuelta(", guion)
        for prohibido in (
            "ClimaxHastur.iniciar(",
            "ClimaxHastur.jugar(",
            "ClimaxHastur.confirmar_victoria(",
            "Acusacion.perder_vida(",
            "Partida.guardar(",
            "OS.execute(",
            "FileAccess.",
            "HTTPRequest.",
        ):
            self.assertNotIn(prohibido, guion)

    def test_contrato_18_casos_en_godot(self) -> None:
        comprobar_contrato(
            self,
            "pruebas/pruebas_cronicas_siete_esferas_2589.gd",
            "Crónicas 2589: 18 pasadas, 0 fallos",
            timeout=45,
        )
