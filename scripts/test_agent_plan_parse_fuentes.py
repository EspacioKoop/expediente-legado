#!/usr/bin/env python3
"""Pruebas de parse_sources en agent_plan_parse.py (#1881, #1901)."""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Carga de agent_plan_parse bajo prueba
MODULE_PATH = ROOT / "scripts" / "agent_plan_parse.py"
SPEC = importlib.util.spec_from_file_location("agent_plan_parse", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)

# Carga de agent_delegated_plan para preparar fuentes JSON de issue/comentarios
DELEGATED_PATH = ROOT / "scripts" / "agent_delegated_plan.py"
SPEC_DEL = importlib.util.spec_from_file_location("agent_delegated_plan", DELEGATED_PATH)
assert SPEC_DEL and SPEC_DEL.loader
mod_delegated = importlib.util.module_from_spec(SPEC_DEL)
sys.modules[SPEC_DEL.name] = mod_delegated
SPEC_DEL.loader.exec_module(mod_delegated)


def _make_issue_source(body: str, comments: list[dict] | None = None, login: str = "eGurucharri", association: str = "OWNER") -> dict:
    issue = {
        "body": body,
        "authorAssociation": association,
        "author": {"login": login},
        "comments": comments or [],
    }
    selected = mod_delegated.select_delegated_plan(issue)
    result = {"found": selected is not None}
    if selected is not None:
        result.update(selected)
    return result


def _make_plan_block(files: list[str] | None = None, goal: str = "corte de prueba") -> str:
    files = ["scripts/test_a.py"] if files is None else files
    return (
        "AGENT_PLAN_BEGIN\n"
        + json.dumps({"files": files, "goal": goal})
        + "\nAGENT_PLAN_END"
    )


class ParseSourcesFuentesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_plan_en_cuerpo_issue(self):
        block = _make_plan_block(files=["scripts/cuerpo.py"], goal="plan en el cuerpo")
        source_data = _make_issue_source(body=block)
        path = self.dir / "delegado_cuerpo.json"
        path.write_text(json.dumps(source_data), encoding="utf-8")

        res = mod.parse_sources([path])
        self.assertIsNotNone(res)
        plan, strategy, found_path = res
        self.assertEqual(["scripts/cuerpo.py"], plan["files"])
        self.assertEqual("plan en el cuerpo", plan["goal"])
        self.assertEqual(path, found_path)
        self.assertEqual("objeto-json", strategy)

    def test_plan_en_comentario_posterior(self):
        comment_block = _make_plan_block(files=["scripts/comentario.py"], goal="plan en comentario")
        comment = {
            "body": comment_block,
            "authorAssociation": "MEMBER",
            "author": {"login": "colaborador"},
        }
        source_data = _make_issue_source(body="Sin plan aquí", comments=[comment])
        path = self.dir / "delegado_comentario.json"
        path.write_text(json.dumps(source_data), encoding="utf-8")

        res = mod.parse_sources([path])
        self.assertIsNotNone(res)
        plan, strategy, found_path = res
        self.assertEqual(["scripts/comentario.py"], plan["files"])
        self.assertEqual("plan en comentario", plan["goal"])
        self.assertEqual(path, found_path)

    def test_dos_planes_gana_el_que_dicte_el_codigo(self):
        # Escenario 1: Múltiples ficheros de entrada. parse_sources evalúa en orden.
        path1 = self.dir / "primer_plan.json"
        path2 = self.dir / "segundo_plan.json"
        path1.write_text(
            json.dumps({"found": True, "plan": {"files": ["scripts/primer.py"], "goal": "primero"}}),
            encoding="utf-8",
        )
        path2.write_text(
            json.dumps({"found": True, "plan": {"files": ["scripts/segundo.py"], "goal": "segundo"}}),
            encoding="utf-8",
        )

        res = mod.parse_sources([path1, path2])
        self.assertIsNotNone(res)
        plan, _, found_path = res
        self.assertEqual(["scripts/primer.py"], plan["files"])
        self.assertEqual(path1, found_path)

        # Escenario 2: Issue con plan en cuerpo y plan posterior en comentario.
        block_body = _make_plan_block(files=["scripts/cuerpo.py"], goal="viejo en cuerpo")
        block_comment = _make_plan_block(files=["scripts/comentario.py"], goal="nuevo en comentario")
        comment = {
            "body": block_comment,
            "authorAssociation": "OWNER",
            "author": {"login": "eGurucharri"},
        }
        source_data = _make_issue_source(body=block_body, comments=[comment])
        path_delegado = self.dir / "delegado_dos_planes.json"
        path_delegado.write_text(json.dumps(source_data), encoding="utf-8")

        res = mod.parse_sources([path_delegado])
        self.assertIsNotNone(res)
        plan_del, _, _ = res
        self.assertEqual(["scripts/comentario.py"], plan_del["files"])
        self.assertEqual("nuevo en comentario", plan_del["goal"])

    def test_plan_dentro_de_bloque_de_codigo_invalido(self):
        block = _make_plan_block(files=["scripts/codigo.py"], goal="bloque de codigo")
        fenced_body = f"Ejemplo de uso:\n```text\n{block}\n```\nNo debe ejecutarse."
        source_data = _make_issue_source(body=fenced_body)
        path = self.dir / "delegado_fence.json"
        path.write_text(json.dumps(source_data), encoding="utf-8")

        res = mod.parse_sources([path])
        self.assertIsNone(res)

    def test_ningun_plan(self):
        source_data = _make_issue_source(body="Solo una duda o reporte sin plan")
        path = self.dir / "delegado_ninguno.json"
        path.write_text(json.dumps(source_data), encoding="utf-8")

        res = mod.parse_sources([path])
        self.assertIsNone(res)

    def test_salta_ficheros_inexistentes_y_sin_plan(self):
        path_no_existe = self.dir / "ausente.json"
        path_sin_plan = self.dir / "vacio.json"
        path_sin_plan.write_text(json.dumps({"found": False}), encoding="utf-8")
        path_con_plan = self.dir / "valido.json"
        path_con_plan.write_text(
            json.dumps({"found": True, "plan": {"files": ["scripts/ok.py"], "goal": "exito"}}),
            encoding="utf-8",
        )

        res = mod.parse_sources([path_no_existe, path_sin_plan, path_con_plan])
        self.assertIsNotNone(res)
        plan, strategy, found_path = res
        self.assertEqual(["scripts/ok.py"], plan["files"])
        self.assertEqual(path_con_plan, found_path)

    def test_fuente_qwen_stream_eventos(self):
        block = _make_plan_block(files=["scripts/qwen.py"], goal="qwen plan")
        events = [
            {"type": "system", "subtype": "init"},
            {
                "type": "assistant",
                "message": {"content": [{"type": "text", "text": block}]},
            },
            {"type": "result", "result": block},
        ]
        path = self.dir / "stdout_qwen.log"
        path.write_text(json.dumps(events), encoding="utf-8")

        res = mod.parse_sources([path])
        self.assertIsNotNone(res)
        plan, strategy, found_path = res
        self.assertEqual(["scripts/qwen.py"], plan["files"])
        self.assertEqual("marcadores", strategy)
        self.assertEqual(path, found_path)

    def test_fuente_gemini_response(self):
        block = _make_plan_block(files=["scripts/gemini.py"], goal="gemini plan")
        path = self.dir / "stdout_gemini.log"
        path.write_text(json.dumps({"response": block}), encoding="utf-8")

        res = mod.parse_sources([path])
        self.assertIsNotNone(res)
        plan, strategy, found_path = res
        self.assertEqual(["scripts/gemini.py"], plan["files"])
        self.assertEqual("marcadores", strategy)
        self.assertEqual(path, found_path)


if __name__ == "__main__":
    unittest.main()
