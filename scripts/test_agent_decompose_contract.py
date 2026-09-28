import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_decompose_contract.py"
SPEC = importlib.util.spec_from_file_location("agent_decompose_contract", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def task(key, *, files=None, depends=None):
    return {
        "key": key,
        "title": f"Corte {key}",
        "goal": f"Implementar {key} sin ampliar alcance",
        "files": files or [f"scripts/{key}.py"],
        "depends_on": depends or [],
    }


def plan(*tasks, decision="decompose"):
    return {
        "decision": decision,
        "reason": "El issue excede un corte seguro" if decision == "decompose" else "Cabe en un corte",
        "subtasks": list(tasks),
    }


class AgentDecomposeContractTest(unittest.TestCase):
    def test_keep_no_crea_subtareas(self):
        result = mod.validate_contract(plan(decision="keep"))
        self.assertEqual("keep", result["decision"])
        self.assertEqual([], result["subtasks"])

    def test_decompose_acepta_hasta_cuatro_cortes(self):
        result = mod.validate_contract(
            plan(task("a"), task("b"), task("c"), task("d"))
        )
        self.assertEqual(4, len(result["subtasks"]))
        self.assertTrue(all(item["ready"] for item in result["subtasks"]))

    def test_decompose_requiere_al_menos_dos_cortes(self):
        with self.assertRaises(mod.ContractError):
            mod.validate_contract(plan(task("a")))

    def test_marca_ready_solo_sin_dependencias(self):
        result = mod.validate_contract(plan(task("a"), task("b", depends=["a"])))
        by_key = {item["key"]: item for item in result["subtasks"]}
        self.assertTrue(by_key["a"]["ready"])
        self.assertFalse(by_key["b"]["ready"])

    def test_rechaza_dependencia_desconocida(self):
        with self.assertRaises(mod.ContractError):
            mod.validate_contract(plan(task("a"), task("b", depends=["x"])))

    def test_rechaza_ciclos(self):
        with self.assertRaises(mod.ContractError):
            mod.validate_contract(
                plan(task("a", depends=["b"]), task("b", depends=["a"]))
            )

    def test_rechaza_rutas_no_concretas(self):
        invalid = [
            "../fuera.py",
            "/absoluta.py",
            "scripts/*.py",
            "scripts/",
            "scripts//x.py",
            " scripts/x.py",
            "scripts\\x.py",
        ]
        for index, path in enumerate(invalid):
            with self.subTest(path=path):
                with self.assertRaises(mod.ContractError):
                    mod.validate_contract(
                        plan(
                            task("a", files=[path]),
                            task("b", files=[f"scripts/ok-{index}.py"]),
                        )
                    )

    def test_rechaza_ruta_compartida_entre_cortes(self):
        with self.assertRaises(mod.ContractError):
            mod.validate_contract(
                plan(
                    task("a", files=["scripts/shared.py"]),
                    task("b", files=["scripts/shared.py"]),
                )
            )

    def test_rechaza_mas_de_doce_rutas_por_corte(self):
        with self.assertRaises(mod.ContractError):
            mod.validate_contract(
                plan(
                    task("a", files=[f"scripts/a{i}.py" for i in range(13)]),
                    task("b"),
                )
            )

    def test_rechaza_campos_extra_para_evitar_drift_del_modelo(self):
        raw = plan(task("a"), task("b"))
        raw["auto_merge"] = True
        with self.assertRaises(mod.ContractError):
            mod.validate_contract(raw)

    def test_no_acepta_keep_con_subtareas(self):
        raw = plan(task("a"), task("b"))
        raw["decision"] = "keep"
        with self.assertRaises(mod.ContractError):
            mod.validate_contract(raw)


if __name__ == "__main__":
    unittest.main()
