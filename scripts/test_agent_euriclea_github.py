import importlib.util
import json
import os
import sys
import unittest
from unittest.mock import patch, call
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_euriclea.py"
SPEC = importlib.util.spec_from_file_location("agent_euriclea", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class TestEuricleaGitHub(unittest.TestCase):
    """Pruebas de la integración con GitHub (`gh`) en `agent_euriclea.py`."""

    @patch.dict(os.environ, {"GITHUB_REPOSITORY": "org/repo-desde-env"}, clear=False)
    @patch.object(mod, "gh")
    def test_repo_actual_desde_entorno(self, mock_gh):
        res = mod.repo_actual()
        self.assertEqual(res, "org/repo-desde-env")
        mock_gh.assert_not_called()

    @patch.dict(os.environ, {}, clear=True)
    @patch.object(mod, "gh")
    def test_repo_actual_desde_gh(self, mock_gh):
        mock_gh.return_value = "  org/repo-desde-gh\n"
        res = mod.repo_actual()
        self.assertEqual(res, "org/repo-desde-gh")
        mock_gh.assert_called_once_with(
            "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"
        )

    @patch.object(mod, "gh")
    def test_listar_prs_filtra_solo_pool(self, mock_gh):
        datos_prs = [
            {
                "number": 10,
                "title": "PR Pool 1",
                "body": "Refs #100",
                "headRefName": "agent/qwen-100-12345",
                "headRefOid": "a" * 40,
                "isCrossRepository": False,
                "labels": [],
            },
            {
                "number": 11,
                "title": "PR no pool",
                "body": "Refs #101",
                "headRefName": "feature/otra-cosa",
                "headRefOid": "b" * 40,
                "isCrossRepository": False,
                "labels": [],
            },
            {
                "number": 12,
                "title": "Fork pool",
                "body": "Refs #102",
                "headRefName": "agent/gemini-102-12345",
                "headRefOid": "c" * 40,
                "isCrossRepository": True,
                "labels": [],
            },
        ]
        mock_gh.return_value = json.dumps(datos_prs)

        prs = mod.listar_prs("mi-org/mi-repo")

        campos = "number,title,body,headRefName,headRefOid,labels,isCrossRepository"
        mock_gh.assert_called_once_with(
            "pr", "list", "--repo", "mi-org/mi-repo", "--state", "open", "--limit", "100", "--json", campos
        )
        self.assertEqual(len(prs), 1)
        self.assertEqual(prs[0]["number"], 10)

    @patch.object(mod, "gh")
    def test_pr_concreta(self, mock_gh):
        datos_pr = {
            "number": 42,
            "title": "Fix bug",
            "body": "Closes #42",
            "headRefName": "agent/qwen-42-99999",
            "headRefOid": "abcdef1234567890abcdef1234567890abcdef12",
            "isCrossRepository": False,
            "labels": [{"name": "revision:pendiente"}],
        }
        mock_gh.return_value = json.dumps(datos_pr)

        pr = mod.pr_concreta("mi-org/mi-repo", 42)

        campos = "number,title,body,headRefName,headRefOid,labels,isCrossRepository"
        mock_gh.assert_called_once_with(
            "pr", "view", "42", "--repo", "mi-org/mi-repo", "--json", campos
        )
        self.assertEqual(pr["number"], 42)
        self.assertEqual(pr["headRefOid"], "abcdef1234567890abcdef1234567890abcdef12")

    @patch.object(mod, "gh")
    def test_comentarios_de(self, mock_gh):
        datos_comentarios = {
            "comments": [
                {"author": {"login": "github-actions"}, "body": "comentario 1"},
                {"author": {"login": "eGurucharri"}, "body": "comentario 2"},
            ]
        }
        mock_gh.return_value = json.dumps(datos_comentarios)

        comentarios = mod.comentarios_de("mi-org/mi-repo", 15)

        mock_gh.assert_called_once_with("pr", "view", "15", "--repo", "mi-org/mi-repo", "--json", "comments")
        self.assertEqual(len(comentarios), 2)
        self.assertEqual(comentarios[0]["body"], "comentario 1")

    @patch.object(mod, "gh")
    def test_candidatas(self, mock_gh):
        sha_20 = "1" * 40
        sha_21 = "2" * 40
        datos_prs = [
            {
                "number": 20,
                "title": "PR sin revisar",
                "body": "Refs #200",
                "headRefName": "agent/qwen-200-11111",
                "headRefOid": sha_20,
                "isCrossRepository": False,
                "labels": [],
            },
            {
                "number": 21,
                "title": "PR ya revisada",
                "body": "Refs #201",
                "headRefName": "agent/qwen-201-22222",
                "headRefOid": sha_21,
                "isCrossRepository": False,
                "labels": [],
            },
        ]
        comentarios_20 = {"comments": []}
        comentarios_21 = {
            "comments": [
                {
                    "author": {"login": "github-actions"},
                    "body": f"<!-- euriclea sha={sha_21} nivel=principal -->",
                }
            ]
        }

        def mock_gh_side_effect(*args, **kwargs):
            if args[:2] == ("pr", "list"):
                return json.dumps(datos_prs)
            if args[:3] == ("pr", "view", "20"):
                return json.dumps(comentarios_20)
            if args[:3] == ("pr", "view", "21"):
                return json.dumps(comentarios_21)
            raise ValueError(f"Argumentos gh inesperados: {args}")

        mock_gh.side_effect = mock_gh_side_effect

        resultado = mod.candidatas("mi-org/mi-repo", mod.PRINCIPAL, ("github-actions",))

        self.assertEqual(len(resultado), 1)
        self.assertEqual(resultado[0]["number"], 20)

    @patch.object(mod, "gh")
    def test_texto_issue_con_numero(self, mock_gh):
        mock_gh.return_value = json.dumps(
            {"title": "Bug en el motor", "body": "Detalle del problema y solución"}
        )

        res = mod.texto_issue("mi-org/mi-repo", 123)

        mock_gh.assert_called_once_with(
            "issue", "view", "123", "--repo", "mi-org/mi-repo", "--json", "title,body"
        )
        self.assertEqual(res, "#123 Bug en el motor\n\nDetalle del problema y solución")

    @patch.object(mod, "gh")
    def test_texto_issue_sin_numero(self, mock_gh):
        res = mod.texto_issue("mi-org/mi-repo", None)

        mock_gh.assert_not_called()
        self.assertEqual(res, "(la PR no enlaza issue)")

    @patch.object(mod, "gh")
    def test_asegurar_etiquetas(self, mock_gh):
        mod.asegurar_etiquetas("mi-org/mi-repo")

        self.assertEqual(mock_gh.call_count, len(mod.ETIQUETAS))
        llamadas_esperadas = [
            call(
                "label",
                "create",
                nombre,
                "--repo",
                "mi-org/mi-repo",
                "--color",
                color,
                "--description",
                descripcion,
                "--force",
            )
            for nombre, (color, descripcion) in mod.ETIQUETAS.items()
        ]
        mock_gh.assert_has_calls(llamadas_esperadas, any_order=True)


if __name__ == "__main__":
    unittest.main()
