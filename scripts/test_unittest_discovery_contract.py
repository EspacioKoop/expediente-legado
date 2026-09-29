import ast
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"


class UnittestDiscoveryContractTest(unittest.TestCase):
    def test_no_hay_tests_top_level_invisibles_para_unittest(self) -> None:
        ocultos: list[str] = []
        for ruta in sorted(SCRIPTS.glob("test_*.py")):
            arbol = ast.parse(ruta.read_text(encoding="utf-8"), filename=str(ruta))
            for nodo in arbol.body:
                if isinstance(nodo, (ast.FunctionDef, ast.AsyncFunctionDef)) and nodo.name.startswith(
                    "test_"
                ):
                    ocultos.append(f"{ruta.name}:{nodo.lineno}:{nodo.name}")
        self.assertEqual(
            ocultos,
            [],
            "unittest discover ignora funciones test_* a nivel de módulo: "
            + ", ".join(ocultos),
        )


if __name__ == "__main__":
    unittest.main()
