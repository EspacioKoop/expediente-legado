from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
AUTOPILOT = ROOT / ".github" / "workflows" / "agent-autopilot.yml"
REPAIR = ROOT / ".github" / "workflows" / "agent-ci-repair.yml"
DENO_MAIN = ROOT / "infra" / "feedback-deno" / "main.ts"
DENO_MEMORY = ROOT / "infra" / "feedback-deno" / "agent_memory.ts"
DENO_CONFIG = ROOT / "infra" / "feedback-deno" / "deno.json"
DENO_README = ROOT / "infra" / "feedback-deno" / "README.md"
AGENTS_DOC = ROOT / "docs" / "agents-autonomos.md"
QWEN = ROOT / "QWEN.md"
GEMINI = ROOT / "GEMINI.md"


class AgentMemoryContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.autopilot = AUTOPILOT.read_text(encoding="utf-8")
        cls.repair = REPAIR.read_text(encoding="utf-8")
        cls.deno_main = DENO_MAIN.read_text(encoding="utf-8")
        cls.deno_memory = DENO_MEMORY.read_text(encoding="utf-8")
        cls.deno_config = json.loads(DENO_CONFIG.read_text(encoding="utf-8"))
        cls.deno_readme = DENO_README.read_text(encoding="utf-8")
        cls.agents_doc = AGENTS_DOC.read_text(encoding="utf-8")
        cls.qwen = QWEN.read_text(encoding="utf-8")
        cls.gemini = GEMINI.read_text(encoding="utf-8")

    def test_memoria_deno_usa_oidc_y_no_secret_nuevo(self):
        self.assertIn('const AGENT_MEMORY_AUDIENCE = "siga98-agent-memory"', self.deno_memory)
        self.assertIn('https://token.actions.githubusercontent.com', self.deno_memory)
        self.assertIn('/.well-known/jwks', self.deno_memory)
        self.assertIn('claims.repository !== repository', self.deno_memory)
        self.assertIn('/.github/workflows/agent-autopilot.yml@', self.deno_memory)
        self.assertIn('/.github/workflows/agent-ci-repair.yml@', self.deno_memory)
        self.assertNotIn("GITHUB_TOKEN", self.deno_memory)

    def test_memoria_es_acotada_y_expira(self):
        self.assertIn("30 * 24 * 60 * 60 * 1000", self.deno_memory)
        self.assertIn("AGENT_MEMORY_SCAN_LIMIT = 50", self.deno_memory)
        self.assertIn("AGENT_MEMORY_RETURN_LIMIT = 8", self.deno_memory)
        self.assertIn("AGENT_MEMORY_MAX_SUMMARY = 1200", self.deno_memory)
        self.assertIn(".slice(0, 8)", self.deno_memory)
        self.assertIn("clean.length >= 12", self.deno_memory)
        self.assertIn("containsPotentialSecret", self.deno_memory)
        self.assertIn('{ expireIn: AGENT_MEMORY_TTL_MS }', self.deno_memory)

    def test_configured_repository_no_es_recursivo_y_valida_env(self):
        bloque = self.deno_main.split("function configuredRepository(): string {", 1)[1].split("\n}", 1)[0]
        self.assertNotIn("configuredRepository()", bloque)
        self.assertIn('Deno.env.get("GITHUB_REPOSITORY")', bloque)
        self.assertIn("DEFAULT_REPOSITORY", bloque)
        self.assertIn("GITHUB_REPOSITORY inválido", bloque)
        self.assertIn("const repository = configuredRepository();", self.deno_main)

    def test_gateway_expone_memoria_sin_romper_reportes(self):
        self.assertIn('import { handleAgentMemory } from "./agent_memory.ts";', self.deno_main)
        self.assertIn('url.pathname.startsWith("/api/agent-memory/")', self.deno_main)
        self.assertIn('url.pathname !== "/api/report"', self.deno_main)
        self.assertIn("agent_memory: true", self.deno_main)
        self.assertIn("version: 2", self.deno_main)
        self.assertIn(
            "token.actions.githubusercontent.com",
            self.deno_config["tasks"]["start"],
        )

    def test_workflows_cargan_normas_wiki_y_memoria(self):
        for workflow in (self.autopilot, self.repair):
            self.assertIn("id-token: write", workflow)
            self.assertIn("GEMINI_CLI_TRUST_WORKSPACE: 'true'", workflow)
            self.assertIn(
                "https://github.com/EspacioKoop/normas_platino.git",
                workflow,
            )
            self.assertIn(
                "https://github.com/EspacioKoop/expediente-legado.wiki.git",
                workflow,
            )
            self.assertIn("siga98-agent-memory", workflow)
            self.assertIn("ACTIONS_ID_TOKEN_REQUEST_TOKEN", workflow)
            self.assertIn("SIGA98_FEEDBACK_FALLBACK_URL", workflow)
            self.assertIn(".agent-memory.json", workflow)
            self.assertNotIn("run_shell_command", workflow)

    def test_autopilot_guarda_solo_memoria_estructurada(self):
        self.assertIn("AGENT_MEMORY_BEGIN", self.autopilot)
        self.assertIn("AGENT_MEMORY_END", self.autopilot)
        self.assertIn("/api/agent-memory/remember", self.autopilot)
        self.assertIn("/api/agent-memory/search", self.autopilot)
        self.assertIn('x.startswith(".agent-")', self.autopilot)
        self.assertIn("rm -rf .agent-platino .agent-wiki", self.autopilot)

    def test_autopilot_acepta_plan_json_con_fence_markdown(self):
        self.assertIn("AGENT_PLAN_BEGIN(.*?)AGENT_PLAN_END", self.autopilot)
        self.assertIn("fenced=re.fullmatch", self.autopilot)
        self.assertIn('(?:json)?\\\\s*(.*?)\\\\s*', self.autopilot)
        self.assertIn("payload=fenced.group(1).strip()", self.autopilot)
        self.assertIn("json.loads(payload)", self.autopilot)
        self.assertNotIn(
            'AGENT_PLAN_BEGIN\\\\s*(\\\\{.*?\\\\})\\\\s*AGENT_PLAN_END',
            self.autopilot,
        )

    def test_reparacion_usa_misma_memoria_y_normas(self):
        self.assertIn("AGENT_MEMORY_BEGIN", self.repair)
        self.assertIn("/api/agent-memory/remember", self.repair)
        self.assertIn("/api/agent-memory/search", self.repair)
        self.assertIn("rm -rf .agent-platino .agent-wiki", self.repair)

    def test_documentacion_fija_jerarquia(self):
        for doc in (self.qwen, self.gemini):
            self.assertIn("Normas Platino", doc)
            self.assertIn("wiki", doc.lower())
            self.assertIn("memoria Deno KV", doc)
            self.assertIn("repositorio/issue/#181/#182 + Normas Platino", doc)

        self.assertIn("Normas Platino, wiki y memoria", self.agents_doc)
        self.assertIn("no necesita un secret nuevo", self.agents_doc)
        self.assertIn("30 días", self.agents_doc)
        self.assertIn("memoria operativa transitoria", self.deno_readme)


if __name__ == "__main__":
    unittest.main()
