"""Pruebas sin red del guard de creación de issues públicos."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import issue_destination_guard as guard


class GuardTests(unittest.TestCase):
    def test_gameplay_and_mythological_hermes_allowed(self):
        cases = [
            ("Corregir cámara de la oficina", "Revisar godot/guion/camara.gd y su regresión."),
            ("Sueño de Hermes mitológico", "Escribir el encuentro onírico con Hermes en Godot."),
            ("Corregir CI de Godot", "Actualizar scripts/test_foo.py para evitar regresión."),
            ("Corte GBC ARIADNE 98", "Objetivo: ROM propia jugable en gbc/minijuegos/ariadne_98."),
        ]
        for title, body in cases:
            with self.subTest(title=title):
                self.assertTrue(guard.permitir_issue("EspacioKoop/expediente-legado", title, body))

    def test_operational_private_scope_rejected(self):
        cases = [
            ("infra(agentes): más workers", "Aumentar slots."),
            ("Plan de Hermes gateway", "Arreglar la cola."),
            ("Router de inferencia", "Actualizar eGurucharri/infra-casa."),
            ("Mistral de pago", "Ajustar capacidad del proveedor."),
            ("Juego: optimizar", "Medir el Beelink y sus recursos."),
            ("Escena de oficina", "Subir un log de /home/usuario/.config/test"),
            ("Arreglar las tareas", "GROQ_API_KEY=abc123 (dato ficticio)"),
            ("Reparar la misión", "AUTH_TOKEN=secreto_simulado"),
            ("Optimizar gameplay", "Endpoint local 192.168.1.22 para QA."),
            ("P0 | agent(mistral-paid): cinemáticas", "Implementar cinematicas Godot."),
            ("Mejorar audio", "Migrar proveedor a WireGuard."),
        ]
        for title, body in cases:
            with self.subTest(title=title):
                self.assertFalse(guard.permitir_issue("EspacioKoop/expediente-legado", title, body))

    def test_other_repository_and_invalid_envelopes(self):
        self.assertFalse(guard.permitir_issue("eGurucharri/infra-casa", "Corregir el juego", "Juego."))
        self.assertFalse(guard.permitir_issue("EspacioKoop/expediente-legado", "1234", "Juego."))
        self.assertFalse(guard.permitir_issue("EspacioKoop/expediente-legado", "Corregir juego", ""))
        self.assertFalse(guard.permitir_issue("EspacioKoop/expediente-legado", "Corregir juego", "x" * 16001))

    def test_decompose_guards_parent_single_plan_and_each_child(self):
        workflow = (Path(__file__).resolve().parents[1] / ".github/workflows/agent-decompose.yml").read_text()
        call = "python3 scripts/issue_destination_guard.py"
        self.assertEqual(workflow.count(call), 4)
        self.assertLess(workflow.index(call), workflow.index('association="$(jq -r'))
        self.assertLess(
            workflow.index(call, workflow.index("plan=\"$(jq -c '{files:.files,goal:.goal}'")),
            workflow.index('gh issue comment "$ISSUE" --repo "$GITHUB_REPOSITORY" --body "$(printf'),
        )
        self.assertLess(
            workflow.index(call, workflow.index('reason="$(jq -r')),
            workflow.index('gh issue comment "$ISSUE" --repo "$GITHUB_REPOSITORY" --body \\'),
        )
        self.assertLess(workflow.rindex(call), workflow.index('url="$(gh issue create'))

    def test_autopilot_and_pool_preflight_and_claim_order(self):
        for name in ("agent-autopilot.yml", "agent-worker.yml"):
            workflow = (Path(__file__).resolve().parents[1] / ".github/workflows" / name).read_text()
            call = "python3 scripts/issue_destination_guard.py"
            with self.subTest(name=name):
                self.assertEqual(workflow.count(call), 3)
                first = workflow.index(call)
                plan = workflow.index(call, first + 1)
                before_push = workflow.index(call, plan + 1)
                self.assertLess(first, plan)
                self.assertLess(plan, workflow.index('claim="CLAIM issue='))
                self.assertIn("--body-file .agent-plan.json", workflow)
                self.assertLess(before_push, workflow.index('git push -u origin "$BRANCH"'))

    def test_cli_denial_does_not_print_private_content(self):
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / "input.md"
            private_value = "API_KEY=EXAMPLE_DO_NOT_PUBLISH"
            file.write_text(private_value, encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(Path(guard.__file__)), "--repo",
                 "EspacioKoop/expediente-legado", "--title", "Escena SIGA 98",
                 "--body-file", str(file)],
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 2)
            self.assertNotIn(private_value, result.stderr + result.stdout)
            self.assertNotIn(folder, result.stderr + result.stdout)


if __name__ == "__main__":
    unittest.main()
