"""Verificar que Crónicas acredita solo la finalización jugada del prólogo."""

from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato

ROOT = Path(__file__).resolve().parents[1]


class CronicasExposicion2589Test(unittest.TestCase):
    def test_emisor_unico_y_sin_semilla_anticipada(self) -> None:
        productor = (ROOT / "godot/guion/dia_escritorio_siga_app.gd").read_text(encoding="utf-8")
        enlace = (ROOT / "godot/guion/cronicas_os98_enlace.gd").read_text(encoding="utf-8")
        contrato = (ROOT / "godot/guion/cronicas_exposicion_2589.gd").read_text(encoding="utf-8")
        self.assertIn("CronicasExposicion2589.registrar_prologo(", productor)
        self.assertIn("prologo_completado.connect(al_completar)", enlace)
        self.assertIn("guardar_estado_aplicaciones()", productor)
        self.assertIn("app.persistir_estado = true", enlace)
        self.assertNotIn("SemillasOniricas.activar_semilla_onirica(", contrato)
        self.assertNotIn("Partida.guardar(", contrato)

    def test_visita_idempotente_guardar_recargar_sin_sueno(self) -> None:
        comprobar_contrato(
            self,
            "pruebas/pruebas_cronicas_exposicion_2589.gd",
            "26 pasadas, 0 fallos",
            timeout=45,
        )
