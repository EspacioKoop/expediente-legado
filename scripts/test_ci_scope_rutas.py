#!/usr/bin/env python3
"""Pruebas para las funciones de clasificación y obtención de rutas en scripts/ci_scope.py."""

from __future__ import annotations

import subprocess
import unittest
from unittest.mock import patch

from scripts.ci_scope import changed_paths, is_evidence_path, is_fast_path


class TestIsEvidencePath(unittest.TestCase):
    """Pruebas para is_evidence_path(path: str) -> bool."""

    def test_rutas_exactas_de_evidencia(self):
        self.assertTrue(is_evidence_path(".github/workflows/benchmark-cc0.yml"))
        self.assertTrue(is_evidence_path("scripts/test_benchmark_cc0.py"))
        self.assertTrue(is_evidence_path("scripts/test_upload_artifact_wrapper_1888.py"))

    def test_workflows_de_evidencia_validos(self):
        self.assertTrue(is_evidence_path(".github/workflows/evidencia-cobertura.yml"))
        self.assertTrue(is_evidence_path(".github/workflows/kubasta-visual-gate-ci.yml"))
        self.assertTrue(is_evidence_path(".github/workflows/cata-audio.yml"))
        self.assertTrue(is_evidence_path(".github/workflows/laboratorio-test.yml"))

    def test_workflows_de_evidencia_invalidos_por_extension(self):
        self.assertFalse(is_evidence_path(".github/workflows/evidencia-cobertura.json"))
        self.assertFalse(is_evidence_path(".github/workflows/cata-audio.md"))

    def test_scripts_de_evidencia_validos(self):
        self.assertTrue(is_evidence_path("scripts/test_evidencia_123.py"))
        self.assertTrue(is_evidence_path("scripts/test_kubasta_visual_gate_check.py"))
        self.assertTrue(is_evidence_path("scripts/test_cata_metricas.py"))
        self.assertTrue(is_evidence_path("scripts/test_laboratorio_ejemplo.py"))

    def test_scripts_de_evidencia_invalidos_por_extension(self):
        self.assertFalse(is_evidence_path("scripts/test_evidencia_123.sh"))
        self.assertFalse(is_evidence_path("scripts/test_cata_metricas.txt"))

    def test_actions_upload_artifact(self):
        self.assertTrue(is_evidence_path(".github/actions/upload-artifact/action.yml"))
        self.assertTrue(is_evidence_path(".github/actions/upload-artifact/README.md"))

    def test_normalizacion_de_barras_y_espacios(self):
        self.assertTrue(is_evidence_path("  scripts\\test_evidencia_abc.py  "))
        self.assertTrue(is_evidence_path(" .github\\workflows\\evidencia-test.yml "))

    def test_rutas_vacias_o_no_evidencia(self):
        self.assertFalse(is_evidence_path(""))
        self.assertFalse(is_evidence_path("   "))
        self.assertFalse(is_evidence_path("src/main.py"))
        self.assertFalse(is_evidence_path("scripts/test_otro_modulo.py"))
        self.assertFalse(is_evidence_path(".github/workflows/ci.yml"))


class TestIsFastPath(unittest.TestCase):
    """Pruebas para is_fast_path(path: str) -> bool."""

    def test_rutas_exactas_fast_path(self):
        self.assertTrue(is_fast_path("docs/agents-autonomos.md"))
        self.assertTrue(is_fast_path("scripts/check_deno_production.py"))
        self.assertTrue(is_fast_path("scripts/test_deno_production_freshness.py"))

    def test_prefijos_fast_path(self):
        self.assertTrue(is_fast_path(".github/workflows/agent-runner.yml"))
        self.assertTrue(is_fast_path(".github/workflows/feedback-deno.yml"))
        self.assertTrue(is_fast_path(".github/workflows/mando-deno.yml"))
        self.assertTrue(is_fast_path("infra/feedback-deno/deno.json"))
        self.assertTrue(is_fast_path("infra/mando-deno/main.ts"))
        self.assertTrue(is_fast_path("docs/agents/manual.md"))
        self.assertTrue(is_fast_path("scripts/agent_helper.py"))
        self.assertTrue(is_fast_path("scripts/test_agent_helper.py"))

    def test_normalizacion_de_barras_y_espacios(self):
        self.assertTrue(is_fast_path("  scripts\\agent_helper.py  "))
        self.assertTrue(is_fast_path(" docs\\agents-autonomos.md "))

    def test_rutas_vacias_o_no_fast_path(self):
        self.assertFalse(is_fast_path(""))
        self.assertFalse(is_fast_path("   "))
        self.assertFalse(is_fast_path("src/game.gd"))
        self.assertFalse(is_fast_path("docs/index.md"))
        self.assertFalse(is_fast_path("scripts/ci_scope.py"))


class TestChangedPaths(unittest.TestCase):
    """Pruebas para changed_paths(base: str, head: str) -> list[str]."""

    @patch("subprocess.check_output")
    def test_changed_paths_salida_sintetica(self, mock_check_output):
        mock_check_output.return_value = "file1.txt\nfile2.py\n\nfile3.gd\n  \n"
        resultado = changed_paths("main", "HEAD")

        mock_check_output.assert_called_once_with(
            ["git", "diff", "--name-only", "main...HEAD"],
            text=True,
        )
        self.assertEqual(resultado, ["file1.txt", "file2.py", "file3.gd"])

    @patch("subprocess.check_output")
    def test_changed_paths_salida_vacia(self, mock_check_output):
        mock_check_output.return_value = "\n  \n"
        resultado = changed_paths("origin/main", "feature-branch")

        mock_check_output.assert_called_once_with(
            ["git", "diff", "--name-only", "origin/main...feature-branch"],
            text=True,
        )
        self.assertEqual(resultado, [])

    @patch("subprocess.check_output")
    def test_changed_paths_error_subprocess(self, mock_check_output):
        mock_check_output.side_effect = subprocess.CalledProcessError(
            returncode=128,
            cmd=["git", "diff", "--name-only", "invalid...HEAD"],
        )
        with self.assertRaises(subprocess.CalledProcessError):
            changed_paths("invalid", "HEAD")


if __name__ == "__main__":
    unittest.main()
