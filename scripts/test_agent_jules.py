"""Contrato del puente de reservas de Jules (#1917).

Jules no publica CLAIM/RELEASE: `agent-jules.yml` lo hace por él con las mismas
herramientas y límites del pool, para que ningún otro agente pise sus rutas.
"""

from pathlib import Path
import re
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "agent-jules.yml"


class PuenteJulesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = WORKFLOW.read_text(encoding="utf-8")
        cls.datos = yaml.safe_load(cls.texto)

    def test_escucha_label_y_cierre_del_issue(self):
        # PyYAML lee la clave `on` como True.
        eventos = self.datos[True]["issues"]["types"]
        self.assertEqual({"labeled", "unlabeled", "closed"}, set(eventos))
        condicion = self.datos["jobs"]["reserva"]["if"]
        self.assertIn("github.event.label.name == 'jules'", condicion)
        self.assertIn("contains(github.event.issue.labels.*.name, 'jules')", condicion)

    def test_permisos_minimos_y_sin_secretos(self):
        self.assertEqual({"contents": "read", "issues": "write"}, self.datos["permissions"])
        self.assertNotIn("secrets.", self.texto)

    def test_valida_con_las_herramientas_del_pool(self):
        self.assertIn("scripts/agent_delegated_plan.py", self.texto)
        self.assertIn("scripts/agent_plan_parse.py", self.texto)
        self.assertIn("vars.AGENT_POOL_MAX_FILES || '1'", self.texto)
        self.assertRegex(self.texto, r'--max-files\s+"\$MAX_FILES"')

    def test_claim_y_release_en_el_registro_activo(self):
        self.assertIn("gestionar_reservas_rollover.py --active", self.texto)
        self.assertRegex(
            self.texto,
            r"CLAIM issue=#\$ISSUE agent=Jules branch=\$branch files=\$files goal=\$goal lease=48h",
        )
        self.assertIn("RELEASE issue=#$ISSUE branch=$branch", self.texto)

    def test_sin_plan_valido_no_hay_reserva(self):
        paso = self.texto[self.texto.index("status=0"):self.texto.index("files=\"$(jq")]
        self.assertIn("agent:needs-human", paso)
        self.assertIn("exit 0", paso)

    def test_no_interpola_texto_del_issue_en_el_script(self):
        # Título y cuerpo son de terceros: solo entran por fichero, nunca por ${{ }}.
        run = "\n".join(
            paso.get("run", "") for paso in self.datos["jobs"]["reserva"]["steps"]
        )
        self.assertNotRegex(run, r"\$\{\{[^}]*github\.event\.issue\.(title|body)")
        self.assertIsNone(re.search(r"\$\{\{", run))


if __name__ == "__main__":
    unittest.main()
