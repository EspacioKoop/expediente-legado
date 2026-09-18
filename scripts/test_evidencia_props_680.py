"""Contrato de evidencia visual y presupuesto para #680."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaProps680Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (ROOT / "godot/pruebas/capturar_props_680.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-props-680.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/props-680/README.md"
        ).read_text(encoding="utf-8")

    def test_captura_recorrido_real_de_dia(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        for archivo in (
            "pickups_casa.png",
            "persiana_atascada.png",
            "persiana_reparada.png",
            "luz_reducida_sin_linterna.png",
            "luz_reducida_con_linterna.png",
        ):
            self.assertIn(archivo, self.captura)
        self.assertIn('dia._entrar_en("casa")', self.captura)
        self.assertIn("persiana.interactuar(dia._caminante)", self.captura)
        self.assertIn('Props.objeto_inventario("palanca_kkryy")', self.captura)
        self.assertIn('Props.objeto_inventario("linterna_kkryy")', self.captura)

    def test_presupuesto_incremental_esta_fijado(self):
        for contrato in (
            "MAX_TRIANGULOS_PROPS := 2000",
            "MAX_MALLAS_PROPS := 12",
            "MAX_SUPERFICIES_PROPS := 16",
            "MAX_LUCES_DINAMICAS := 1",
        ):
            self.assertIn(contrato, self.captura)
        self.assertIn('"sombras_luz_portatil_max": 0', self.captura)
        self.assertIn("instancia.mesh.get_faces().size()", self.captura)
        self.assertIn("instancia.mesh.get_surface_count()", self.captura)
        self.assertIn('"presupuesto_cumplido"', self.captura)

    def test_workflow_reacciona_al_glb_real_y_publica_artifact(self):
        self.assertIn("'godot/assets/modelos/street_furniture/**'", self.workflow)
        self.assertIn("'godot/assets/procedencia.json'", self.workflow)
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("evidencia-props-680/manifest.json", self.workflow)
        self.assertIn("len(set(hashes)) != 5", self.workflow)
        self.assertIn('if not manifest["presupuesto_cumplido"]', self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)

    def test_workflow_verifica_los_dos_usos_reales(self):
        self.assertIn(
            'pickups["ids_visibles"] != ["linterna_kkryy", "palanca_kkryy"]',
            self.workflow,
        )
        self.assertIn('if despues["consecuencia_presente"]', self.workflow)
        self.assertIn('if sin_luz["luces"] != 0', self.workflow)
        self.assertIn(
            'if con_luz["luces"] != 1 or con_luz["sombras"] != 0',
            self.workflow,
        )

    def test_documentacion_separa_gate_provisional_y_final(self):
        self.assertIn("provisional", self.docs.lower())
        self.assertIn("git lfs", self.docs.lower())
        self.assertIn("revisión humana", self.docs.lower())
        self.assertIn("2.000", self.docs)
        self.assertIn("972", self.docs)
        self.assertIn("manifest.json", self.docs)
        self.assertIn("no certifica fps", self.docs.lower())


if __name__ == "__main__":
    unittest.main()
