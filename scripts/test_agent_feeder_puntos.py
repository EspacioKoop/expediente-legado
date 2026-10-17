#!/usr/bin/env python3
"""Pruebas unitarias para score_points en scripts/agent_feeder.py."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_feeder.py"

SPEC = importlib.util.spec_from_file_location("agent_feeder", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)

score_points = mod.score_points
score = mod.score


class TestAgentFeederPuntos(unittest.TestCase):
    """Pruebas puras y sin red para score_points() en agent_feeder.py."""

    def test_issue_vacio_o_sin_coincidencias_devuelve_cero(self) -> None:
        self.assertEqual(score_points({}), 0)
        self.assertEqual(score_points({"title": "", "labels": []}), 0)
        self.assertEqual(
            score_points(
                {
                    "title": "Característica genérica",
                    "labels": ["feature", "documentacion"],
                }
            ),
            0,
        )

    def test_labels_none_lanza_type_error(self) -> None:
        # GitHub siempre devuelve `labels` como lista: `None` es una entrada
        # inválida y fallar con TypeError es preferible a puntuarla como 0.
        with self.assertRaises(TypeError):
            score_points({"title": None, "labels": None})

    def test_etiqueta_bug_suma_40_puntos(self) -> None:
        issue = {"title": "Error en login", "labels": ["bug"]}
        self.assertEqual(score_points(issue), 40)

    def test_etiquetas_de_prioridad(self) -> None:
        p3 = {"labels": ["prioridad:P3"]}
        p2 = {"labels": ["prioridad:P2"]}
        p1 = {"labels": ["prioridad:P1"]}
        p0 = {"labels": ["prioridad:P0"]}

        self.assertEqual(score_points(p3), 25)
        self.assertEqual(score_points(p2), 15)
        self.assertEqual(score_points(p1), 5)
        self.assertEqual(score_points(p0), 0)

    def test_prioridad_multiple_respeta_orden_elif(self) -> None:
        # P3 aparece antes en la lógica del if/elif
        issue_p3_p2 = {"labels": ["prioridad:P3", "prioridad:P2"]}
        self.assertEqual(score_points(issue_p3_p2), 25)

        issue_p2_p1 = {"labels": ["prioridad:P2", "prioridad:P1"]}
        self.assertEqual(score_points(issue_p2_p1), 15)

    def test_prefijos_de_titulo_infra_y_test(self) -> None:
        self.assertEqual(score_points({"title": "infra: actualizar runner"}), 30)
        self.assertEqual(score_points({"title": "infra(ci): refactor pip"}), 30)
        self.assertEqual(score_points({"title": "test: añadir tests de puntos"}), 30)
        self.assertEqual(score_points({"title": "test(feeder): test de unidad"}), 30)

        # Insensible a mayúsculas
        self.assertEqual(score_points({"title": "INFRA: REFACTOR"}), 30)
        self.assertEqual(score_points({"title": "Test(core): test"}), 30)

        # No coincide si está en medio del título
        self.assertEqual(score_points({"title": "Fix para infra: bug"}), 0)

    def test_etiqueta_area_accesibilidad_suma_5_puntos(self) -> None:
        issue = {"labels": ["area:accesibilidad"]}
        self.assertEqual(score_points(issue), 5)

    def test_soporta_etiquetas_como_strings_o_diccionarios(self) -> None:
        issue_dict_labels = {
            "title": "infra: prueba",
            "labels": [
                {"name": "bug"},
                {"name": "prioridad:P3"},
                {"name": "area:accesibilidad"},
            ],
        }
        # 40 (bug) + 25 (P3) + 30 (infra:) + 5 (accesibilidad) = 100
        self.assertEqual(score_points(issue_dict_labels), 100)

        issue_mixed_labels = {
            "labels": [
                "bug",
                {"name": "prioridad:P2"},
                123,  # Ignorado sin fallar
                None,  # Ignorado sin fallar
            ]
        }
        # 40 (bug) + 15 (P2) = 55
        self.assertEqual(score_points(issue_mixed_labels), 55)

    def test_puntuacion_acumulativa(self) -> None:
        max_score_issue = {
            "title": "infra(db): corregir migración",
            "labels": ["bug", "prioridad:P3", "area:accesibilidad"],
        }
        # 40 (bug) + 25 (P3) + 30 (infra) + 5 (accesibilidad) = 100
        self.assertEqual(score_points(max_score_issue), 100)

        combo_issue = {
            "title": "test: probar accesibilidad",
            "labels": ["prioridad:P1", "area:accesibilidad"],
        }
        # 0 (no bug) + 5 (P1) + 30 (test:) + 5 (accesibilidad) = 40
        self.assertEqual(score_points(combo_issue), 40)

    def test_orden_relativo_y_desempates(self) -> None:
        issue_high = {
            "number": 10,
            "title": "infra: bug critico",
            "labels": ["bug", "prioridad:P3"],
            "createdAt": "2026-10-01T10:00:00Z",
        }  # 40 + 25 + 30 = 95 puntos

        issue_med = {
            "number": 20,
            "title": "test: refactor",
            "labels": ["prioridad:P2"],
            "createdAt": "2026-10-01T08:00:00Z",
        }  # 15 + 30 = 45 puntos

        issue_low = {
            "number": 30,
            "title": "Feature nueva",
            "labels": ["prioridad:P1"],
            "createdAt": "2026-10-01T09:00:00Z",
        }  # 5 puntos

        self.assertGreater(score_points(issue_high), score_points(issue_med))
        self.assertGreater(score_points(issue_med), score_points(issue_low))

        # Comprobación de ordenación con score() tuple (-points, created, number)
        issues = [issue_low, issue_high, issue_med]
        sorted_issues = sorted(issues, key=score)
        self.assertEqual(sorted_issues, [issue_high, issue_med, issue_low])

        # Empate en puntos: desempata por antigüedad (createdAt más antiguo primero)
        issue_tie_older = {
            "number": 100,
            "title": "test: uno",
            "labels": ["bug"],  # 40 + 30 = 70 puntos
            "createdAt": "2026-09-01T00:00:00Z",
        }
        issue_tie_newer = {
            "number": 101,
            "title": "test: dos",
            "labels": ["bug"],  # 40 + 30 = 70 puntos
            "createdAt": "2026-10-01T00:00:00Z",
        }
        self.assertEqual(
            score_points(issue_tie_older), score_points(issue_tie_newer)
        )
        self.assertLess(score(issue_tie_older), score(issue_tie_newer))

        # Empate en puntos y createdAt: desempata por number menor
        issue_tie_num1 = {
            "number": 5,
            "title": "bug menor",
            "labels": ["bug"],
            "createdAt": "2026-10-01T00:00:00Z",
        }
        issue_tie_num2 = {
            "number": 15,
            "title": "bug menor",
            "labels": ["bug"],
            "createdAt": "2026-10-01T00:00:00Z",
        }
        self.assertEqual(
            score_points(issue_tie_num1), score_points(issue_tie_num2)
        )
        self.assertLess(score(issue_tie_num1), score(issue_tie_num2))


if __name__ == "__main__":
    unittest.main()
