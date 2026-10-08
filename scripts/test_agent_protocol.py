import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_protocol.py"
SPEC = importlib.util.spec_from_file_location("agent_protocol", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class AgentProtocolTest(unittest.TestCase):
    def packet(self):
        issue = {
            "number": 1866,
            "title": "Mejorar handoff",
            "body": "- [ ] conserva scope\n- [x] emite evidencia",
        }
        plan = {"files": ["scripts/a.py", "scripts/test_a.py"], "goal": "hacer contrato"}
        return mod.build_task_packet(
            issue,
            plan,
            repository="EspacioKoop/expediente-legado",
            base_sha="a" * 40,
            policy_sha="b" * 40,
            provider="qwen",
            worker="qwen-primary",
        )

    def test_task_packet_es_versionado_y_acotado(self):
        packet = self.packet()
        self.assertEqual(1, packet["schema"])
        self.assertEqual("TASK", packet["message_type"])
        self.assertEqual(12, packet["scope"]["max_files"])
        self.assertEqual(["scripts/a.py", "scripts/test_a.py"], packet["scope"]["allowed_files"])
        self.assertIn("do_not_weaken_assertions_to_make_tests_green", packet["scope"]["domain_constraints"])
        self.assertEqual(2, len(packet["acceptance_from_issue"]))

    def test_prompt_lleva_scope_y_result_contract(self):
        prompt = mod.render_worker_prompt(self.packet(), "qwen")
        self.assertIn("scripts/a.py", prompt)
        self.assertIn("AGENT_RESULT_BEGIN", prompt)
        self.assertIn('"message_type": "RESULT"', prompt)
        self.assertIn("read_file/grep_search", prompt)
        self.assertIn("No hagas commit, push, PR ni merge", prompt)

    def test_prompt_multifichero_enumera_rutas_sin_contexto_adicional(self):
        packet = self.packet()
        prompt = mod.render_worker_prompt(packet, "qwen")
        self.assertIn("Rutas permitidas (lista cerrada)", prompt)
        self.assertIn("- scripts/a.py", prompt)
        self.assertIn("- scripts/test_a.py", prompt)
        self.assertNotIn("Único fichero que puedes modificar", prompt)
        self.assertIn("ninguna ruta fuera de la lista", prompt)
        self.assertIn("No leas AGENTS.md", prompt)

    def test_prompt_es_autosuficiente_y_prohibe_contexto_extra(self):
        # #1901: los workers agotaban turnos leyendo normas, wiki y memorias.
        issue = {
            "number": 1901,
            "title": "Tarea de un fichero",
            "body": "Cambia X por Y en la funcion f.\n\nAGENT_PLAN_BEGIN\n"
            '{"files":["scripts/a.py"],"goal":"g"}\nAGENT_PLAN_END\n',
        }
        packet = mod.build_task_packet(
            issue,
            {"files": ["scripts/a.py"], "goal": "cambiar X por Y"},
            repository="EspacioKoop/expediente-legado",
            base_sha="a" * 40,
            policy_sha="",
            provider="qwen",
            worker="qwen-fallback-2",
            max_files=1,
        )
        self.assertEqual(1, packet["scope"]["max_files"])
        self.assertNotIn("AGENT_PLAN_BEGIN", packet["objective"]["instructions"])
        prompt = mod.render_worker_prompt(packet, "qwen")
        self.assertIn("Cambia X por Y en la funcion f.", prompt)
        self.assertIn("cambiar X por Y", prompt)
        self.assertIn("No leas AGENTS.md", prompt)
        self.assertIn(".agent-platino/", prompt)
        self.assertNotIn("Lee primero '.agent-task-packet.json'", prompt)

    def test_max_files_rechaza_planes_mas_grandes(self):
        with self.assertRaisesRegex(ValueError, "excede 1 rutas"):
            mod.build_task_packet(
                {"number": 1, "title": "t", "body": ""},
                {"files": ["a.py", "b.py"], "goal": "g"},
                repository="r/r",
                base_sha="a" * 40,
                policy_sha="",
                provider="qwen",
                worker="w",
                max_files=1,
            )

    def test_instrucciones_largas_se_recortan(self):
        texto = mod._instructions("x" * (mod.MAX_INSTRUCTIONS + 500))
        self.assertLessEqual(len(texto), mod.MAX_INSTRUCTIONS + 40)
        self.assertIn("recortadas", texto)

    def test_result_anidado_se_parsea_sin_regex_fragil(self):
        packet = self.packet()
        raw = """texto
AGENT_RESULT_BEGIN
{"schema":1,"message_type":"RESULT","task_id":"%s","base_sha":"%s","status":"done",
"summary":"ok","facts":["f"],"assumptions":[],"verified":["pytest: ok"],"unknowns":[],
"changes":[{"path":"scripts/a.py","reason":"fix"}],
"evidence":[{"kind":"test","detail":"1 passed"}],"unresolved":[],"next_action":"review"}
AGENT_RESULT_END
""" % (packet["task_id"], packet["base_sha"])
        result = mod.parse_result(raw)
        self.assertTrue(result["valid"])
        self.assertEqual("scripts/a.py", result["changes"][0]["path"])
        self.assertEqual(100.0, result["contract_coverage_pct"])

    def test_metric_detecta_cambio_no_reportado(self):
        packet = self.packet()
        result = {
            "valid": True,
            "task_id": packet["task_id"],
            "base_sha": packet["base_sha"],
            "changes": [{"path": "scripts/a.py", "reason": "x"}],
            "evidence": [{"kind": "test", "detail": "ok"}],
            "next_action": "review",
            "contract_coverage_pct": 100.0,
        }
        metrics = mod.result_metrics(packet, result, ["scripts/a.py", "scripts/test_a.py"])
        self.assertEqual(["scripts/test_a.py"], metrics["unreported_changed_files"])
        self.assertGreater(metrics["handoff_loss_proxy_pct"], 0)

    def test_sin_resultado_no_bloquea_parser_pero_mide_perdida_total(self):
        packet = self.packet()
        result = mod.parse_result("sin contrato")
        self.assertFalse(result["valid"])
        metrics = mod.result_metrics(packet, result, ["scripts/a.py"])
        self.assertEqual(100.0, metrics["handoff_loss_proxy_pct"])

    def test_recover_result_conserva_hechos_autoritativos_sin_validar_contrato(self):
        packet = self.packet()
        invalid = mod.parse_result("respuesta libre sin delimitadores")
        recovered = mod.recover_result(packet, invalid, "respuesta libre sin delimitadores", ["scripts/a.py"])
        self.assertFalse(recovered["valid"])
        self.assertTrue(recovered["recovered"])
        self.assertEqual("partial", recovered["status"])
        self.assertEqual(packet["task_id"], recovered["task_id"])
        self.assertEqual(
            [{"path": "scripts/a.py", "reason": "cambio observado por el workflow; motivo estructurado no disponible"}],
            recovered["changes"],
        )
        metrics = mod.result_metrics(packet, recovered, ["scripts/a.py"])
        self.assertFalse(metrics["result_contract_valid"])
        self.assertTrue(metrics["result_recovered"])
        self.assertLess(metrics["handoff_loss_proxy_pct"], 100.0)
        self.assertGreater(metrics["handoff_loss_proxy_pct"], 0.0)

    def test_recover_result_sin_diff_queda_bloqueado(self):
        packet = self.packet()
        invalid = mod.parse_result("")
        recovered = mod.recover_result(packet, invalid, "", [])
        self.assertEqual("blocked", recovered["status"])
        self.assertEqual([], recovered["changes"])
    def test_b2b_rechaza_tipo_desconocido_o_sin_schema(self):
        self.assertIsNone(mod.normalize_message({"schema": 1, "message_type": "CHAT"}))
        self.assertIsNone(mod.normalize_message({"message_type": "QUESTION"}))
        self.assertEqual(
            "QUESTION",
            mod.normalize_message({"schema": 1, "message_type": "question"})["message_type"],
        )

    def test_cli_result_escribe_payload(self):
        packet = self.packet()
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            packet_path = root / "packet.json"
            packet_path.write_text(json.dumps(packet), encoding="utf-8")
            summary = root / "summary.txt"
            summary.write_text("sin contrato", encoding="utf-8")
            changed = root / "changed.txt"
            changed.write_text("scripts/a.py\n", encoding="utf-8")
            output = root / "out.json"
            old = sys.argv
            try:
                sys.argv = [
                    "agent_protocol.py", "result",
                    "--summary-file", str(summary),
                    "--packet", str(packet_path),
                    "--changed-files", str(changed),
                    "--output", str(output),
                ]
                self.assertEqual(0, mod.main())
            finally:
                sys.argv = old
            payload = json.loads(output.read_text(encoding="utf-8"))
            self.assertFalse(payload["result"]["valid"])
            self.assertTrue(payload["result"]["recovered"])
            self.assertEqual("partial", payload["result"]["status"])
            self.assertTrue(payload["metrics"]["result_recovered"])
            self.assertLess(payload["metrics"]["handoff_loss_proxy_pct"], 100.0)


if __name__ == "__main__":
    unittest.main()
