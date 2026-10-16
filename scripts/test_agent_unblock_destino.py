import unittest

from scripts.agent_unblock_destino import destino


def cuerpo(ficheros, proveedor=None):
    extra = f"<!-- agent-provider: {proveedor} -->\n" if proveedor else ""
    plan = '{"files": [%s], "goal": "x"}' % ", ".join(f'"{f}"' for f in ficheros)
    return f"Texto\n{extra}AGENT_PLAN_BEGIN\n{plan}\nAGENT_PLAN_END\n"


class AgentUnblockDestinoTest(unittest.TestCase):
    def test_asm_python_y_docs_van_a_jules(self):
        self.assertEqual(destino(cuerpo(["gbc/minijuegos/ariadne_98/main.asm"])), "jules")
        self.assertEqual(destino(cuerpo(["scripts/test_x.py"])), "jules")
        self.assertEqual(destino(cuerpo(["docs/a.md", ".github/workflows/x.yml"])), "jules")

    def test_godot_va_al_pool(self):
        self.assertEqual(destino(cuerpo(["godot/guion/a.gd"])), "agent:auto")
        self.assertEqual(destino(cuerpo(["docs/a.md", "godot/escenas/b.tscn"])), "agent:auto")

    def test_proveedor_explicito_manda(self):
        self.assertEqual(destino(cuerpo(["docs/a.md"], "qwen")), "agent:qwen")
        self.assertEqual(destino(cuerpo(["godot/guion/a.gd"], "gemini")), "agent:gemini")
        self.assertEqual(destino(cuerpo(["godot/guion/a.gd"], "jules")), "jules")
        self.assertEqual(destino(cuerpo(["gbc/a.asm"], "auto")), "jules")

    def test_sin_plan_o_plan_roto_va_al_pool(self):
        self.assertEqual(destino("sin plan"), "agent:auto")
        self.assertEqual(destino("AGENT_PLAN_BEGIN\n{roto\nAGENT_PLAN_END"), "agent:auto")


if __name__ == "__main__":
    unittest.main()
