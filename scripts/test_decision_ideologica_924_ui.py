"""Regresión de la superficie visible y lectura social del vertical #924."""

import csv
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot" / "guion" / "visor_pronosticos_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "visor.tscn"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
DIALOGO = ROOT / "godot" / "guion" / "dialogo_ideologico.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class DecisionIdeologica924UITest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.dialogo = DIALOGO.read_text(encoding="utf-8")
        with TEXTOS.open(encoding="utf-8", newline="") as archivo:
            cls.textos = {fila["clave"]: fila["es"] for fila in csv.DictReader(archivo)}

    def test_el_visor_real_monta_la_capa_postcierre(self) -> None:
        self.assertIn(
            'path="res://guion/visor_pronosticos_app.gd"',
            self.escena,
        )
        self.assertIn(
            'extends "res://guion/visor_anexos_app.gd"',
            self.visor,
        )

    def test_la_ui_reutiliza_el_contrato_y_persiste_sin_reescribir_hechos(self) -> None:
        for contrato in (
            "DecisionIdeologicaExpediente.definicion",
            "DecisionIdeologicaExpediente.disponible",
            "DecisionIdeologicaExpediente.opciones",
            "DecisionIdeologicaExpediente.opcion_registrada",
            "DecisionIdeologicaExpediente.resolver",
            "_guardar_o_avisar()",
        ):
            self.assertIn(contrato, self.visor)
        self.assertNotIn('estado["veredictos"]', self.visor)
        self.assertNotIn('estado["pistas_descubiertas"]', self.visor)
        self.assertNotIn('"neoliberal"', self.visor)

    def test_el_cunado_reacciona_solo_al_evento_observable(self) -> None:
        self.assertIn(
            'companero.nombre_visible != tr("COMPA_CUNADO")',
            self.dia,
        )
        self.assertIn("DialogoIdeologico.SUPERFICIE_OFICINA_CUNADO", self.dia)
        self.assertIn("DialogoIdeologico.registrar_respuesta(", self.dia)
        self.assertIn('_guardar_o_avisar("")', self.dia)

        self.assertIn(
            '"requiere_evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL',
            self.dialogo,
        )
        self.assertIn(
            '"evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL',
            self.dialogo,
        )
        self.assertIn(
            '"actor": DecisionIdeologicaExpediente.ACTOR_CUNADO',
            self.dialogo,
        )
        self.assertIn("registrar_lectura_social(", self.dialogo)
        for reaccion in (
            "cierre_colectivo",
            "cierre_procedimental",
            "cierre_negociado",
        ):
            self.assertIn(f'"reaccion": "{reaccion}"', self.dialogo)

    def test_todo_el_texto_visible_sale_del_catalogo(self) -> None:
        esperadas = {
            "VISOR_DECISION_924_TITULO",
            "VISOR_DECISION_924_AYUDA",
            "VISOR_DECISION_924_BLOQUEADA",
            "VISOR_DECISION_924_REGISTRADA",
            "VISOR_DECISION_924_RESPONSABILIDAD",
            "VISOR_DECISION_924_REVISION",
            "VISOR_DECISION_924_CONCILIACION",
            "IDEOLOGIA_924_CUNADO_COLECTIVO",
            "IDEOLOGIA_924_CUNADO_PROCEDIMIENTO",
            "IDEOLOGIA_924_CUNADO_NEGOCIADO",
        }
        self.assertTrue(esperadas.issubset(self.textos))


if __name__ == "__main__":
    unittest.main()
