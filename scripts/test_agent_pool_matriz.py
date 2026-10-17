import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_pool.py"
SPEC = importlib.util.spec_from_file_location("agent_pool", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def make_issue(
    number: int,
    *labels: str,
    created: str = "2026-10-17T10:00:00Z",
    preferred: str | None = None,
    planned_files: list[str] | None = None,
    planned_bytes: int | None = None,
    body: str = "",
) -> dict:
    result = {
        "number": number,
        "createdAt": created,
        "labels": [{"name": label} for label in labels],
        "body": body,
    }
    if preferred is not None:
        result["preferredProvider"] = preferred
    if planned_files is not None:
        result["plannedFiles"] = planned_files
    if planned_bytes is not None:
        result["plannedBytes"] = planned_bytes
    return result


def make_worker(
    worker_id: str,
    provider: str = "qwen",
    backend: str | None = None,
    healthy: bool = True,
    occupied: bool = False,
    score: float = 50.0,
    tier: int = 1,
) -> dict:
    w = {
        "worker": worker_id,
        "provider": provider,
        "healthy": healthy,
        "occupied": occupied,
        "score": score,
        "tier": tier,
    }
    if backend is not None:
        w["backend"] = backend
    return w


class TestAgentPoolMatriz(unittest.TestCase):
    def test_listas_vacias(self):
        issues_validos = [make_issue(1, "agent:auto")]
        workers_validos = [make_worker("w1", "qwen")]

        # Ambos vacíos
        matriz_ambos_vacios = mod.build_matrix([], [])
        self.assertEqual(matriz_ambos_vacios, {"include": []})

        # Issues vacíos, workers presentes
        matriz_issues_vacios = mod.build_matrix([], workers_validos)
        self.assertEqual(matriz_issues_vacios, {"include": []})

        # Workers vacíos, issues presentes
        matriz_workers_vacios = mod.build_matrix(issues_validos, [])
        self.assertEqual(matriz_workers_vacios, {"include": []})

    def test_mas_issues_que_workers(self):
        issues = [
            make_issue(1, "agent:auto", created="2026-10-17T10:00:00Z"),
            make_issue(2, "agent:auto", created="2026-10-17T10:01:00Z"),
            make_issue(3, "agent:auto", created="2026-10-17T10:02:00Z"),
        ]
        workers = [
            make_worker("w1", "qwen"),
            make_worker("w2", "gemini"),
        ]

        matriz = mod.build_matrix(issues, workers)
        tasks = matriz.get("include", [])

        # Debe acotarse por el número de workers disponibles (2)
        self.assertEqual(len(tasks), 2)
        assigned_issues = [t["issue"] for t in tasks]
        self.assertEqual(assigned_issues, [1, 2])

    def test_mas_workers_que_issues(self):
        issues = [
            make_issue(10, "agent:auto", created="2026-10-17T10:00:00Z"),
        ]
        workers = [
            make_worker("w1", "qwen"),
            make_worker("w2", "gemini"),
            make_worker("w3", "qwen"),
        ]

        matriz = mod.build_matrix(issues, workers)
        tasks = matriz.get("include", [])

        # Debe acotarse por el número de issues elegibles (1)
        self.assertEqual(len(tasks), 1)
        self.assertEqual(tasks[0]["issue"], 10)

    def test_max_parallel_por_debajo_de_ambos(self):
        issues = [
            make_issue(100 + i, "agent:auto", created=f"2026-10-17T10:{i:02d}:00Z")
            for i in range(5)
        ]
        workers = [
            make_worker(f"w{i}", "qwen" if i % 2 == 0 else "gemini")
            for i in range(5)
        ]

        matriz = mod.build_matrix(issues, workers, max_parallel=2)
        tasks = matriz.get("include", [])

        # Debe acotarse por max_parallel=2
        self.assertEqual(len(tasks), 2)
        self.assertEqual([t["issue"] for t in tasks], [100, 101])

    def test_estructura_retorno_y_fichero_temporal(self):
        issues = [
            make_issue(1, "agent:auto", planned_files=["scripts/a.py"]),
            make_issue(2, "agent:qwen", planned_files=["scripts/b.py"]),
        ]
        workers = [
            make_worker("w1", "qwen", backend="groq", score=90.0),
            make_worker("w2", "gemini", backend="gemini", score=80.0),
        ]

        matriz = mod.build_matrix(issues, workers)

        # Verificación de estructura observable
        self.assertIsInstance(matriz, dict)
        self.assertIn("include", matriz)
        tasks = matriz["include"]
        self.assertIsInstance(tasks, list)
        self.assertEqual(len(tasks), 2)

        for task in tasks:
            self.assertIn("issue", task)
            self.assertIn("provider", task)
            self.assertIn("backend", task)
            self.assertIn("worker", task)
            self.assertIsInstance(task["issue"], int)
            self.assertIsInstance(task["provider"], str)
            self.assertIsInstance(task["backend"], str)
            self.assertIsInstance(task["worker"], str)

        # Prueba de serialización observable en fichero temporal
        with tempfile.TemporaryDirectory() as tmpdir:
            out_file = Path(tmpdir) / "matrix.json"
            out_file.write_text(json.dumps(matriz, ensure_ascii=False), encoding="utf-8")

            contenido = json.loads(out_file.read_text(encoding="utf-8"))
            self.assertEqual(contenido, matriz)


if __name__ == "__main__":
    unittest.main()
