from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / ".github" / "actions" / "upload-artifact" / "action.yml"
GBC = ROOT / ".github" / "workflows" / "gbc-fixtures.yml"
CI_BRAIN = ROOT / ".github" / "workflows" / "ci-brain.yml"
FAMILIA_EVIDENCIA = [
    ROOT / ".github" / "workflows" / nombre
    for nombre in (
        "evidencia-calle-277.yml",
        "evidencia-casa-133.yml",
        "evidencia-hogar-227.yml",
        "evidencia-gato-787.yml",
        "evidencia-vida-1998.yml",
        "evidencia-minotauro-437.yml",
        "evidencia-hidra-439.yml",
        "evidencia-ryu-440.yml",
        "evidencia-vecinos-673.yml",
        "evidencia-comercios-676.yml",
        "evidencia-trafico-vial-225.yml",
        "evidencia-simurgh-658.yml",
        "evidencia-castillo-947.yml",
        "evidencia-sueno-284.yml",
        "evidencia-web98-794.yml",
        "evidencia-texto-corrupto-806.yml",
        "evidencia-sueno-786.yml",
        "oficina-visual-gate-126.yml",
        "npc-visual-gate-275.yml",
        "evidencia-rocketbox-oficina-1319.yml",
        "evidencia-densidad-282.yml",
        "evidencia-props-680.yml",
        "evidencia-mitologias-435.yml",
        "evidencia-vfx-1473.yml",
        "evidencia-props-1474.yml",
        "evidencia-materiales-399.yml",
        "benchmark-cc0.yml",
        "laboratorio-sonoro-1475.yml",
        "cata-ambientes-119.yml",
    )
]


class UploadArtifactWrapper1888Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.wrapper = WRAPPER.read_text(encoding="utf-8")
        cls.gbc = GBC.read_text(encoding="utf-8")
        cls.ci_brain = CI_BRAIN.read_text(encoding="utf-8")
        cls.familia = [ruta.read_text(encoding="utf-8") for ruta in FAMILIA_EVIDENCIA]

    def test_wrapper_fija_upstream_por_sha_y_version(self):
        self.assertRegex(
            self.wrapper,
            re.compile(r"uses: actions/upload-artifact@[0-9a-f]{40}\s+# v\d+\.\d+\.\d+"),
        )
        self.assertNotRegex(self.wrapper, r"actions/upload-artifact@v\d")

    def test_wrapper_expone_y_reenvia_inputs_del_smoke(self):
        for nombre in ("name", "path", "if-no-files-found", "retention-days"):
            self.assertIn(f"  {nombre}:", self.wrapper)
            self.assertIn("$" + "{{ inputs." + nombre + " }}", self.wrapper)

    def test_workflows_smoke_usan_wrapper_sin_pin_duplicado(self):
        for workflow in (self.gbc, self.ci_brain, *self.familia):
            self.assertIn("uses: ./.github/actions/upload-artifact", workflow)
            self.assertNotIn("actions/upload-artifact@", workflow)
            self.assertLess(
                workflow.index("actions/checkout@"),
                workflow.index("uses: ./.github/actions/upload-artifact"),
            )

    def test_workflows_migrados_reaccionan_a_cambios_del_wrapper(self):
        self.assertIn('".github/actions/upload-artifact/**"', self.gbc)
        for workflow in self.familia:
            self.assertIn(".github/actions/upload-artifact/**", workflow)


if __name__ == "__main__":
    unittest.main()
