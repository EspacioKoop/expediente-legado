from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot" / "pruebas" / "capturar_rocketbox_oficina_1319.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "evidencia-rocketbox-oficina-1319.yml"
DOC = ROOT / "docs" / "evidencias" / "rocketbox-oficina-1319" / "README.md"


class EvidenciaRocketboxOficina1319Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = CAPTURA.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_matriz_cubre_los_cuatro_estados(self):
        for estado in ("pie", "sentado", "telefono", "conversacion"):
            self.assertIn(f'"nombre": "{estado}"', self.captura)
        self.assertIn("for estado in pie sentado telefono conversacion; do", self.workflow)
        self.assertIn('test -s "$salida/$estado.png"', self.workflow)
        for clip in ("idle", "sentado_hablando", "telefono", "conversar"):
            self.assertIn(f'"clip": "{clip}"', self.captura)

    def test_usa_oficina_y_companeros_reales(self):
        self.assertIn("EspaciosCatalogo.OFICINA.duplicate(true)", self.captura)
        self.assertIn("Companeros.plantilla(1319)", self.captura)
        self.assertIn("Companeros.cuerpo_de(quien)", self.captura)
        self.assertIn("Modelos.persona(", self.captura)
        self.assertIn("CompaneroIdle3D.new()", self.captura)
        self.assertIn("OficinaUtileria.montar(_mundo)", self.captura)
        self.assertIn("OficinaAssetsCc0.montar(_mundo)", self.captura)

    def test_exige_clip_rocketbox_y_postura_valida(self):
        self.assertIn("AnimacionesRocketbox.tiene(pieza, clip)", self.captura)
        self.assertIn('actual.begins_with("rocketbox/")', self.captura)
        self.assertIn('"LeftFoot"', self.captura)
        self.assertIn('"RightFoot"', self.captura)
        self.assertIn('"Head"', self.captura)
        self.assertIn("CompaneroIdle3D.ALTURA_ASIENTO", self.captura)
        self.assertIn('"pie_min_y"', self.captura)
        self.assertIn('"cabeza_y"', self.captura)

    def test_ci_no_se_hace_pasarlo_por_gpu_real(self):
        self.assertIn('"gpu_real": OS.get_environment("SIGA98_GPU_REAL") == "1"', self.captura)
        self.assertIn('assert data["gpu_real"] is False', self.workflow)
        self.assertIn("xvfb-run", self.workflow)
        self.assertIn("mesa-vulkan-drivers", self.workflow)
        self.assertNotIn("SIGA98_GPU_REAL=1", self.workflow)

    def test_documenta_el_pase_fisico_real(self):
        self.assertIn("DISPLAY=:0 SIGA98_GPU_REAL=1", self.doc)
        self.assertIn("no sustituye", self.doc)
        self.assertIn("GPU real", self.doc)
        self.assertIn("brazos, hombros y cuello", self.doc)
        self.assertIn("rocketbox/*", self.doc)

    def test_workflow_publica_manifest_y_capturas(self):
        self.assertIn("uses: ./.github/actions/upload-artifact", self.workflow)
        self.assertNotIn("actions/upload-artifact@", self.workflow)
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("SIGA-98-rocketbox-oficina-1319-", self.workflow)
        self.assertIn("capturar_rocketbox_oficina_1319.gd", self.workflow)


if __name__ == "__main__":
    unittest.main()
