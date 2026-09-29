import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_pool_backpressure.py"
SPEC = importlib.util.spec_from_file_location("agent_pool_backpressure", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class AgentPoolBackpressureTest(unittest.TestCase):
    def test_sin_carga_respeta_requested(self):
        self.assertEqual(
            4,
            mod.effective_capacity(4, queued=0, in_progress=0, budget=12),
        )

    def test_resta_queued_e_in_progress_del_presupuesto(self):
        self.assertEqual(
            3,
            mod.effective_capacity(6, queued=4, in_progress=5, budget=12),
        )

    def test_presupuesto_agotado_devuelve_cero(self):
        self.assertEqual(
            0,
            mod.effective_capacity(6, queued=7, in_progress=5, budget=12),
        )

    def test_cap_global_sigue_en_seis(self):
        self.assertEqual(
            6,
            mod.effective_capacity(99, queued=0, in_progress=0, budget=99),
        )

    def test_entradas_negativas_no_crean_capacidad_fantasma(self):
        self.assertEqual(
            0,
            mod.effective_capacity(-1, queued=-4, in_progress=-3, budget=-2),
        )


if __name__ == "__main__":
    unittest.main()
