import importlib.util
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_failure_policy.py"
SPEC = importlib.util.spec_from_file_location("agent_failure_policy", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class AgentFailurePolicyTest(unittest.TestCase):
    def test_quota_y_overload_rotan_provider(self):
        for text in (
            "HTTP 429",
            "503 Service temporarily overloaded",
            "RESOURCE_EXHAUSTED",
            "rate limit exceeded",
        ):
            with self.subTest(text=text):
                result = mod.classify_failure(stage="implementing", text=text)
                self.assertEqual("quota_or_overload", result["category"])
                self.assertEqual("rotate_provider", result["action"])

    def test_claim_drift_pide_expandir_claim_y_gana_a_texto(self):
        result = mod.classify_failure(
            stage="implementing",
            claim_drift=True,
            text="503 overloaded",
        )
        self.assertEqual("claim_drift", result["category"])
        self.assertEqual("expand_claim", result["action"])

    def test_no_changes_no_cambia_de_worker(self):
        result = mod.classify_failure(stage="implementing", no_changes=True)
        self.assertEqual("no_changes", result["category"])
        self.assertEqual("stop_noop", result["action"])

    def test_cancelacion_es_neutral(self):
        result = mod.classify_failure(
            stage="validating",
            job_status="cancelled",
            text="AssertionError",
        )
        self.assertEqual("cancelled", result["category"])
        self.assertEqual("requeue_neutral", result["action"])

    def test_timeout_o_turn_limit_no_se_trata_como_cuota(self):
        for text in ("operation timed out", "FatalTurnLimitedError", "maxSessionTurns"):
            with self.subTest(text=text):
                result = mod.classify_failure(stage="implementing", text=text)
                self.assertEqual("timeout", result["category"])
                self.assertEqual("split_or_same_worker", result["action"])

    def test_fallo_de_test_conserva_worker(self):
        for text in (
            "AssertionError: expected true",
            "1 test failed",
            "workflow failure",
            "would reformat godot/guion/x.gd",
            "gdlint: max-returns",
        ):
            with self.subTest(text=text):
                result = mod.classify_failure(stage="preflight", text=text)
                self.assertEqual("test_or_preflight", result["category"])
                self.assertEqual("same_worker_fix", result["action"])

    def test_transporte_roto_rota_provider(self):
        result = mod.classify_failure(
            stage="implementing",
            text="connection reset by peer",
        )
        self.assertEqual("provider_or_transport", result["category"])
        self.assertEqual("rotate_provider", result["action"])

    def test_logs_se_leen_desde_fichero_y_se_acotan(self):
        with tempfile.TemporaryDirectory() as tmp:
            first = Path(tmp) / "a.log"
            second = Path(tmp) / "b.log"
            first.write_text("503 Service temporarily overloaded", encoding="utf-8")
            second.write_text("detalle posterior", encoding="utf-8")
            text = mod.read_text_files([first, second], max_bytes=12)
        self.assertEqual(12, len(text.encode("utf-8")))
        self.assertTrue(text.startswith("503 Service"))

    def test_log_inexistente_no_rompe_clasificacion(self):
        text = mod.read_text_files([Path("/definitivamente/no/existe.log")])
        self.assertEqual("", text)
        result = mod.classify_failure(stage="implementing", text=text)
        self.assertEqual("human_review", result["action"])

    def test_lectura_real_respeta_presupuesto_entre_ficheros(self):
        lecturas = []

        class LogAcotado(io.BytesIO):
            def read(self, size=-1):
                if size < 0 or size > 12:
                    raise AssertionError("lectura de log sin límite")
                data = super().read(size)
                lecturas.append((size, len(data)))
                return data

        def abrir(path, mode):
            self.assertEqual(mode, "rb")
            if path.name == "a.log":
                return LogAcotado(b"503")
            if path.name == "b.log":
                return LogAcotado(b"overloaded" * 1000)
            raise AssertionError("no debe abrir logs al agotar el presupuesto")

        with patch.object(Path, "open", autospec=True, side_effect=abrir):
            text = mod.read_text_files(
                [Path("a.log"), Path("b.log"), Path("c.log")], max_bytes=12
            )
        self.assertEqual("503\noverloade", text)
        self.assertEqual([(12, 3), (9, 9)], lecturas)

    def test_presupuesto_cero_no_abre_logs(self):
        with patch.object(Path, "open", side_effect=AssertionError("no abrir")):
            self.assertEqual("", mod.read_text_files([Path("a.log")], max_bytes=0))
            self.assertEqual("", mod.read_text_files([Path("a.log")], max_bytes=-1))

    def test_log_inaccesible_no_consume_presupuesto(self):
        with tempfile.TemporaryDirectory() as tmp:
            log = Path(tmp) / "b.log"
            log.write_bytes(b"HTTP 429" + b"x" * 10000)
            text = mod.read_text_files([Path(tmp), log], max_bytes=8)
        self.assertEqual("HTTP 429", text)

    def test_utf8_cortado_no_rompe_clasificacion(self):
        with tempfile.TemporaryDirectory() as tmp:
            log = Path(tmp) / "utf8.log"
            log.write_text("503 é", encoding="utf-8")
            text = mod.read_text_files([log], max_bytes=5)
        self.assertEqual("503 \ufffd", text)
        self.assertEqual(
            "rotate_provider", mod.classify_failure(stage="implementing", text=text)["action"]
        )

    def test_desconocido_escala_a_humano(self):
        result = mod.classify_failure(stage="publishing", text="fallo raro")
        self.assertEqual("unknown", result["category"])
        self.assertEqual("human_review", result["action"])


if __name__ == "__main__":
    unittest.main()
