import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_delegated_plan.py"
SPEC = importlib.util.spec_from_file_location("agent_delegated_plan", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def source(body, association="MEMBER", login="eGurucharri", **author):
    return {
        "body": body,
        "authorAssociation": association,
        "author": {"login": login, **author},
    }


def block(files=None, goal="hacer corte"):
    files = ["scripts/a.py"] if files is None else files
    import json
    return (
        "AGENT_PLAN_BEGIN\n"
        + json.dumps({"files": files, "goal": goal})
        + "\nAGENT_PLAN_END"
    )


class AgentDelegatedPlanTest(unittest.TestCase):
    def test_acepta_plan_de_owner(self):
        issue = source(block(), association="OWNER")
        selected = mod.select_delegated_plan(issue)
        self.assertEqual(["scripts/a.py"], selected["plan"]["files"])
        self.assertEqual("issue", selected["source"])

    def test_ignora_fuente_no_confiable(self):
        issue = source(block(), association="NONE", login="externo")
        self.assertIsNone(mod.select_delegated_plan(issue))

    def test_ignora_bots_aunque_tengan_association(self):
        issue = source(block(), association="MEMBER", login="robot[bot]")
        self.assertIsNone(mod.select_delegated_plan(issue))
        issue = source(block(), association="MEMBER", login="robot", __typename="Bot")
        self.assertIsNone(mod.select_delegated_plan(issue))

    def test_ignora_ejemplo_en_fence_markdown(self):
        issue = source("Ejemplo:\n```text\n" + block() + "\n```\nNo debe ejecutar.")
        self.assertIsNone(mod.select_delegated_plan(issue))

    def test_marcadores_deben_estar_en_lineas_propias(self):
        issue = source(
            'texto AGENT_PLAN_BEGIN\n{"files":["scripts/a.py"],"goal":"x"}\n'
            "AGENT_PLAN_END texto"
        )
        self.assertIsNone(mod.select_delegated_plan(issue))

    def test_gana_el_plan_valido_mas_reciente(self):
        issue = source(block(goal="viejo"), association="OWNER")
        issue["comments"] = [
            source(block(goal="nuevo"), association="COLLABORATOR", login="colab")
        ]
        selected = mod.select_delegated_plan(issue)
        self.assertEqual("nuevo", selected["plan"]["goal"])
        self.assertEqual("comment", selected["source"])
        self.assertEqual("colab", selected["author"])

    def test_plan_invalido_reciente_no_pisa_el_ultimo_valido(self):
        issue = source(block(goal="valido"), association="OWNER")
        issue["comments"] = [
            source(
                "AGENT_PLAN_BEGIN\n"
                '{"files":"scripts/a.py","goal":"invalido"}\n'
                "AGENT_PLAN_END",
                association="MEMBER",
            )
        ]
        selected = mod.select_delegated_plan(issue)
        self.assertEqual("valido", selected["plan"]["goal"])

    def test_no_aplica_validacion_de_rutas_del_claim(self):
        issue = source(
            block(files=["../fuera", "uno", "dos"], goal="reserva valida despues"),
            association="OWNER",
        )
        selected = mod.select_delegated_plan(issue)
        self.assertEqual(["../fuera", "uno", "dos"], selected["plan"]["files"])


if __name__ == "__main__":
    unittest.main()
