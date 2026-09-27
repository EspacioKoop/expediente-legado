"""Contrato estático de evidencia reproducible para #1474."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaProps1474Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (
            ROOT / "godot/pruebas/capturar_props_puestos_1474.gd"
        ).read_text(encoding="utf-8")
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-props-1474.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/props-1474/README.md"
        ).read_text(encoding="utf-8")
        cls.proyecto = (ROOT / "godot/project.godot").read_text(encoding="utf-8")

    def test_usa_oficina_real_y_camara_jugable(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        self.assertIn('dia._entrar_en("archivo")', self.captura)
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("dia._caminante.situar(", self.captura)
        self.assertIn("camara.look_at(objetivo", self.captura)
        self.assertIn('"camara": "jugable"', self.captura)
        self.assertIn('"hud": false', self.captura)

    def test_cubre_tres_puestos_y_retira_npcs_despues_del_montaje(self):
        self.assertIn(
            'const PUESTOS := ["PuestoUtileria1", "PuestoUtileria2", "PuestoUtileria3"]',
            self.captura,
        )
        self.assertIn("var perfiles_antes := _perfiles(dia._mundo)", self.captura)
        self.assertIn("var retirados := _retirar_companeros(dia._mundo)", self.captura)
        self.assertIn('nodo.has_meta("companero_id")', self.captura)
        self.assertIn('"companeros_retirados": retirados', self.captura)
        self.assertIn('"companeros_visibles": _contar_companeros(dia._mundo)', self.captura)
        self.assertIn('"perfil_props"', self.captura)
        self.assertIn('"perfil_antes_retirar_npc"', self.captura)

    def test_publica_firma_de_composicion_sin_autoaprobar(self):
        self.assertIn('var archivo := "puesto-%d.png"', self.captura)
        self.assertIn('"hijos": hijos', self.captura)
        self.assertIn('"sha256": FileAccess.get_sha256(destino)', self.captura)
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)

    def test_workflow_usa_forward_plus_y_exige_tres_firmas_distintas(self):
        self.assertIn('renderer/rendering_method="forward_plus"', self.proyecto)
        self.assertIn("xvfb-run -a godot4 --path godot", self.workflow)
        self.assertNotIn("--rendering-method gl_compatibility", self.workflow)
        self.assertIn("for puesto in 1 2 3; do", self.workflow)
        self.assertIn(
            'test -s "evidencia-props-1474/puesto-${puesto}.png"',
            self.workflow,
        )
        self.assertIn("manifest.json", self.workflow)
        self.assertIn('manifest.get("companeros_visibles") != 0', self.workflow)
        self.assertIn('len(set(perfiles)) != 3', self.workflow)
        self.assertIn('len(set(firmas)) != 3', self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-props-1474-${{ github.sha }}", self.workflow)

    def test_documentacion_reserva_el_veredicto_a_revision_humana(self):
        texto = self.docs.lower()
        self.assertIn("tres capturas", texto)
        self.assertIn("sin npc", texto)
        self.assertIn("cámara jugable", texto)
        self.assertIn("forward+", texto)
        self.assertIn("revisión humana", texto)
        self.assertIn("escala", texto)
        self.assertIn("oclusión", texto)
        self.assertIn("no autoaprueba", texto)


if __name__ == "__main__":
    unittest.main()
