import unittest

from scripts.agent_unblock_destino import ficheros_del_plan


class FicherosDelPlanTest(unittest.TestCase):
    def test_cuerpo_con_plan_valido(self):
        cuerpo = (
            "Texto explicativo inicial\n"
            "AGENT_PLAN_BEGIN\n"
            '{"files": ["scripts/a.py", "docs/b.md"], "goal": "objetivo"}\n'
            "AGENT_PLAN_END\n"
            "Texto final"
        )
        self.assertEqual(ficheros_del_plan(cuerpo), ["scripts/a.py", "docs/b.md"])

    def test_cuerpo_con_json_roto(self):
        cuerpo = (
            "AGENT_PLAN_BEGIN\n"
            '{"files": ["scripts/a.py", broken json}\n'
            "AGENT_PLAN_END"
        )
        self.assertEqual(ficheros_del_plan(cuerpo), [])

    def test_cuerpo_sin_plan(self):
        cuerpo = "Este texto no contiene ningun bloque de plan de agente."
        self.assertEqual(ficheros_del_plan(cuerpo), [])

    def test_cuerpo_con_plan_dentro_de_bloque_de_codigo(self):
        """Un plan envuelto en un bloque de codigo NO es un plan delegado.

        Es el mismo contrato que `agent_delegated_plan.py`, que ignora los planes
        dentro de fences Markdown: si aqui se aceptara, el desbloqueo podria mover
        una tarea con un plan que el resto del pool rechaza.
        """
        cuerpo = (
            "AGENT_PLAN_BEGIN\n"
            "```json\n"
            '{"files": ["scripts/test.py"], "goal": "demo"}\n'
            "```\n"
            "AGENT_PLAN_END"
        )
        self.assertEqual(ficheros_del_plan(cuerpo), [])

    def test_cuerpo_con_multiples_planes_retorna_el_ultimo(self):
        cuerpo = (
            "AGENT_PLAN_BEGIN\n"
            '{"files": ["old.py"], "goal": "v1"}\n'
            "AGENT_PLAN_END\n"
            "AGENT_PLAN_BEGIN\n"
            '{"files": ["new.py"], "goal": "v2"}\n'
            "AGENT_PLAN_END"
        )
        self.assertEqual(ficheros_del_plan(cuerpo), ["new.py"])

    def test_cuerpo_sin_clave_files_retorna_lista_vacia(self):
        cuerpo = (
            "AGENT_PLAN_BEGIN\n"
            '{"goal": "sin archivos"}\n'
            "AGENT_PLAN_END"
        )
        self.assertEqual(ficheros_del_plan(cuerpo), [])


if __name__ == "__main__":
    unittest.main()
