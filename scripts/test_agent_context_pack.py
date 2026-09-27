import importlib.util
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_context_pack.py"
SPEC = importlib.util.spec_from_file_location("agent_context_pack", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mod)


class AgentContextPackTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.wiki = self.root / "wiki"
        self.wiki.mkdir()
        (self.wiki / "Home.md").write_text(
            "# Expediente Legado\n\nÍndice general del proyecto.\n",
            encoding="utf-8",
        )
        (self.wiki / "SIGA-98.md").write_text(
            "# SIGA-98\n\n## Expedientes\nLa terminal consulta pistas, anexos y archivado.\n",
            encoding="utf-8",
        )
        (self.wiki / "Sueños.md").write_text(
            "# Sueños\n\n## Anomalías\nGeometría onírica, lluvia y símbolos.\n",
            encoding="utf-8",
        )
        agents = self.wiki / "Agentes"
        agents.mkdir()
        (agents / "CI.md").write_text(
            "# CI de agentes\n\nLos workflows reparan fallos y conservan el CLAIM.\n",
            encoding="utf-8",
        )

    def tearDown(self):
        self.tmp.cleanup()

    def test_prioriza_titulo_heading_y_ruta(self):
        pages = mod.load_pages(self.wiki)
        ranked = mod.rank_pages(
            pages,
            "Profundizar expedientes de SIGA y anexos del terminal",
            ["godot/guion/siga_terminal.gd"],
        )
        self.assertTrue(ranked)
        self.assertEqual(ranked[0].page.relpath, "SIGA-98.md")
        self.assertGreater(ranked[0].score, 0)
        self.assertTrue(ranked[0].reasons)

    def test_ranking_es_determinista(self):
        pages = mod.load_pages(self.wiki)
        args = (pages, "CI agentes workflows CLAIM", [".github/workflows/ci.yml"])
        first = [(item.page.relpath, item.score) for item in mod.rank_pages(*args)]
        second = [(item.page.relpath, item.score) for item in mod.rank_pages(*args)]
        self.assertEqual(first, second)

    def test_respetar_limite_de_paginas_y_bytes(self):
        pages = mod.load_pages(self.wiki)
        ranked = mod.rank_pages(
            pages,
            "SIGA expedientes sueños CI agentes workflows",
            ["godot/guion/siga_terminal.gd", ".github/workflows/ci.yml"],
        )
        home = next(page for page in pages if page.relpath == "Home.md")
        result = mod.build_pack(
            ranked,
            max_pages=2,
            max_bytes=1200,
            fallback_home=home,
        )
        self.assertLessEqual(len(result.encode("utf-8")), 1200)
        self.assertLessEqual(result.count("**Motivo de selección:**"), 2)
        self.assertIn("## Selección", result)

    def test_fallback_home_si_no_hay_coincidencias(self):
        pages = mod.load_pages(self.wiki)
        ranked = mod.rank_pages(pages, "xylophonium quasar", [])
        home = next(page for page in pages if page.relpath == "Home.md")
        result = mod.build_pack(
            ranked,
            max_pages=4,
            max_bytes=2000,
            fallback_home=home,
        )
        self.assertIn("Home.md", result)
        self.assertIn("fallback: Home", result)

    def test_ignora_markdown_oculto_symlink_y_archivos_grandes(self):
        hidden = self.wiki / ".oculto"
        hidden.mkdir()
        (hidden / "Secret.md").write_text("# Secret\n", encoding="utf-8")

        target = self.root / "outside.md"
        target.write_text("# Fuera\n", encoding="utf-8")
        (self.wiki / "Link.md").symlink_to(target)

        (self.wiki / "Grande.md").write_bytes(b"x" * (mod.MAX_SOURCE_BYTES + 1))

        paths = {page.relpath for page in mod.load_pages(self.wiki)}
        self.assertNotIn(".oculto/Secret.md", paths)
        self.assertNotIn("Link.md", paths)
        self.assertNotIn("Grande.md", paths)

    def test_pack_explica_jerarquia_y_motivos(self):
        pages = mod.load_pages(self.wiki)
        ranked = mod.rank_pages(pages, "sueños anomalías", [])
        result = mod.build_pack(
            ranked,
            max_pages=3,
            max_bytes=4000,
            fallback_home=None,
        )
        self.assertIn("Normas Platino", result)
        self.assertIn("Motivo de selección", result)
        self.assertIn("Sueños.md", result)


if __name__ == "__main__":
    unittest.main()
