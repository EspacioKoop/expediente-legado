import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIGURADOR = ROOT / "scripts" / "configurar_sentry.py"
INSTALADOR = ROOT / "scripts" / "preparar_sentry.sh"
WORKFLOW = ROOT / ".github" / "workflows" / "alpha-playtest.yml"
GITIGNORE = ROOT / ".gitignore"


def cargar_modulo():
    spec = importlib.util.spec_from_file_location("configurar_sentry", CONFIGURADOR)
    modulo = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(modulo)
    return modulo


class SentryAlphaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.modulo = cargar_modulo()

    def test_configuracion_es_idempotente_y_preserva_el_proyecto(self):
        original = """config_version=5

[application]

config/name=\"SIGA-98\"

[rendering]

renderer/rendering_method=\"forward_plus\"
"""
        kwargs = dict(
            dsn="https://public@example.ingest.sentry.io/123",
            release="siga98@abcdef",
            environment="alpha",
            dist="42.1",
        )
        una = self.modulo.configurar_proyecto(original, **kwargs)
        dos = self.modulo.configurar_proyecto(una, **kwargs)
        self.assertEqual(una, dos)
        self.assertIn('config/name="SIGA-98"', una)
        self.assertIn("[sentry]", una)
        self.assertIn("options/auto_init=true", una)
        self.assertIn('options/release="siga98@abcdef"', una)
        self.assertIn('options/environment="alpha"', una)
        self.assertIn('options/dist="42.1"', una)
        self.assertIn("options/tracing/traces_sample_rate=0.0", una)

    def test_rechaza_dsn_no_https(self):
        with self.assertRaises(ValueError):
            self.modulo.configurar_proyecto(
                "config_version=5\n",
                dsn="http://example.invalid/1",
                release="siga98@x",
                environment="alpha",
                dist="",
            )

    def test_instalador_fija_release_hash_y_no_versiona_binarios(self):
        texto = INSTALADOR.read_text(encoding="utf-8")
        self.assertIn('VERSION="${SENTRY_GODOT_VERSION:-2.2.0}"', texto)
        self.assertIn("539cca58ff4188dafcd1318e03396fa303ea1ae5b2eda6f96a055146af44b156", texto)
        self.assertIn("sha256sum --check --strict", texto)
        self.assertIn("addons/sentry", texto)
        self.assertIn("godot/addons/sentry/", GITIGNORE.read_text(encoding="utf-8"))

    def test_alpha_es_opt_in_por_secret_y_etiqueta_el_build(self):
        texto = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("SENTRY_DSN: ${{ secrets.SENTRY_DSN }}", texto)
        self.assertIn("bash scripts/preparar_sentry.sh", texto)
        self.assertIn("python3 scripts/configurar_sentry.py", texto)
        self.assertIn('siga98@${GITHUB_SHA}', texto)
        self.assertIn('--environment "alpha"', texto)
        self.assertLess(
            texto.index("Preparar Sentry para alpha"),
            texto.index("Importar proyecto antes del smoke"),
        )


if __name__ == "__main__":
    unittest.main()
