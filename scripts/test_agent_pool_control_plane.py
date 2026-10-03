from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
POOL = ROOT / ".github" / "workflows" / "agent-pool.yml"
WORKER = ROOT / ".github" / "workflows" / "agent-worker.yml"
DENO_MAIN = ROOT / "infra" / "feedback-deno" / "main.ts"
DENO_POOL = ROOT / "infra" / "feedback-deno" / "agent_pool_state.ts"
DENO_WORKFLOW = ROOT / ".github" / "workflows" / "feedback-deno.yml"


class AgentPoolControlPlaneContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pool = POOL.read_text(encoding="utf-8")
        cls.worker = WORKER.read_text(encoding="utf-8")
        cls.deno_main = DENO_MAIN.read_text(encoding="utf-8")
        cls.deno_pool = DENO_POOL.read_text(encoding="utf-8")
        cls.deno_workflow = DENO_WORKFLOW.read_text(encoding="utf-8")

    def test_deno_expone_control_plane_oidc(self):
        self.assertIn('const AGENT_POOL_AUDIENCE = "siga98-agent-pool"', self.deno_pool)
        self.assertIn("AGENT_POOL_LEASE_TTL_MS = 30 * 60 * 1000", self.deno_pool)
        self.assertIn("AGENT_POOL_EVENT_TTL_MS = 7 * 24 * 60 * 60 * 1000", self.deno_pool)
        self.assertIn("kv.atomic()", self.deno_pool)
        self.assertIn(".check(current)", self.deno_pool)
        self.assertIn("/.github/workflows/agent-pool.yml@", self.deno_pool)
        self.assertIn("/.github/workflows/agent-worker.yml@", self.deno_pool)
        self.assertNotIn("GITHUB_TOKEN", self.deno_pool)

    def test_api_tiene_lease_transiciones_release_y_status(self):
        for endpoint in (
            "/api/agent-pool/acquire",
            "/api/agent-pool/transition",
            "/api/agent-pool/release",
            "/api/agent-pool/status",
            "/api/agent-pool/worker-status",
            "/api/agent-pool/worker-health/status",
            "/api/agent-pool/worker-health/report",
        ):
            self.assertIn(endpoint, self.deno_pool)
        for state in ("planning", "implementing", "validating", "publishing"):
            self.assertIn(f'"{state}"', self.deno_pool)

    def test_lease_transporta_rutas_de_forma_retrocompatible(self):
        self.assertIn("files: string[];", self.deno_pool)
        self.assertIn("function cleanFiles(value: unknown): string[]", self.deno_pool)
        self.assertIn("const files = cleanFiles(input.files);", self.deno_pool)
        self.assertIn("files,", self.deno_pool)
        self.assertIn('Object.hasOwn(input, "files")', self.deno_pool)
        self.assertIn("files: lease.files ?? []", self.deno_pool)
        self.assertIn("value.slice(0, 12)", self.deno_pool)
        self.assertIn('path.split("/").includes("..")', self.deno_pool)

    def test_deno_bloquea_rutas_entre_leases_y_libera_solo_propias(self):
        self.assertIn('["agent_pool", "file_lock", path]', self.deno_pool)
        self.assertIn("interface AgentPoolFileLock", self.deno_pool)
        self.assertIn("function ownsFileLock(", self.deno_pool)
        self.assertIn("function liveForeignLock(", self.deno_pool)
        self.assertIn('error: "file_conflict"', self.deno_pool)
        self.assertIn("kv.get<AgentPoolFileLock>(fileLockKey(path))", self.deno_pool)
        self.assertIn(".set(fileLockKey(files[index]), fileLock(lease, files[index], now)", self.deno_pool)
        self.assertIn("const lockPaths = [...new Set([...previousFiles, ...nextFiles])]", self.deno_pool)
        self.assertIn("atomic.delete(fileLockKey(path))", self.deno_pool)
        self.assertIn("ownsFileLock(entry.value, lease)", self.deno_pool)
        self.assertIn("expireIn: AGENT_POOL_LEASE_TTL_MS", self.deno_pool)

    def test_gateway_anuncia_control_plane(self):
        self.assertIn('import { handleAgentPool } from "./agent_pool_state.ts";', self.deno_main)
        self.assertIn('url.pathname.startsWith("/api/agent-pool/")', self.deno_main)
        self.assertIn("agent_pool_control: true", self.deno_main)
        self.assertIn("version: 4", self.deno_main)
        self.assertIn("agent_pool_worker_health: true", self.deno_main)

    def test_dispatcher_filtra_leases_y_drena(self):
        self.assertIn("siga98-agent-pool", self.pool)
        self.assertIn("/api/agent-pool/status", self.pool)
        self.assertIn("github-fallback", self.worker)
        self.assertIn("drain:", self.pool)
        self.assertIn("gh workflow run agent-pool.yml", self.pool)
        self.assertIn("requested_max", self.pool)

    def test_dispatcher_filtra_slots_ocupados_sin_cambiar_refill(self):
        self.assertIn("/api/agent-pool/worker-status", self.pool)
        self.assertIn("occupancy_from_deno=true", self.pool)
        self.assertIn("Slots ocupados (Deno KV)", self.pool)
        self.assertIn("Ocupación KV no disponible", self.pool)
        self.assertIn("{occupied:", self.pool)
        self.assertIn("drain:\n", self.pool)
        self.assertNotIn('worker-status" --refill', self.pool)

    def test_dispatcher_filtra_slots_ocupados_con_fallback(self):
        self.assertIn("/api/agent-pool/worker-status", self.pool)
        self.assertIn("occupancy_from_deno=true", self.pool)
        self.assertIn('occupied:', self.pool)
        self.assertIn("Ocupación KV no disponible", self.pool)
        self.assertIn('((.occupied // false) | not)', self.pool)
        self.assertIn('if healthy is False or occupied is True:', (
            ROOT / "scripts" / "agent_pool.py"
        ).read_text(encoding="utf-8"))

    def test_dispatcher_filtra_workers_con_lease_activo_sin_perder_fallback(self):
        self.assertIn("/api/agent-pool/worker-status", self.pool)
        self.assertIn("occupancy_from_deno=true", self.pool)
        self.assertIn("Slots ocupados (Deno KV)", self.pool)
        self.assertIn("Ocupación KV no disponible", self.pool)
        self.assertIn('{occupied: (.worker as $w | ($occupied | index($w)) != null)}', self.pool)
        self.assertIn('((.occupied // false) | not)', self.pool)
        self.assertIn('url.pathname === "/api/agent-pool/worker-status"', self.deno_pool)

    def test_health_kv_es_primario_y_1713_solo_fallback(self):
        self.assertIn("/api/agent-pool/worker-health/status", self.pool)
        self.assertIn("health_from_deno=true", self.pool)
        self.assertIn("Health KV no disponible", self.pool)
        self.assertIn("/api/agent-pool/worker-health/report", self.worker)
        self.assertIn("health_reported=true", self.worker)
        self.assertIn("AGENT_POOL_SLOT_UNHEALTHY", self.worker)
        self.assertIn("AGENT_POOL_MIN_COOLDOWN_MS", self.deno_pool)
        self.assertIn("AGENT_POOL_MAX_COOLDOWN_MS", self.deno_pool)

    def test_worker_adquiere_renueva_y_libera(self):
        self.assertIn("/api/agent-pool/acquire", self.worker)
        self.assertIn('"$control_code" == 409', self.worker)
        self.assertIn("control=deno-conflict", self.worker)
        self.assertIn("/api/agent-pool/transition", self.worker)
        self.assertIn("/api/agent-pool/release", self.worker)
        self.assertIn("Liberar lease Deno KV", self.worker)
        self.assertIn("continue-on-error: true", self.worker)

    def test_ci_incluye_el_modulo_de_control_plane(self):
        self.assertIn("agent_pool_state.ts", self.deno_workflow)


if __name__ == "__main__":
    unittest.main()
