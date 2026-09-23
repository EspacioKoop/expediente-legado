"""Contrato de evidencia reproducible para el gate visual de #282."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaDensidad282Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (ROOT / "godot/pruebas/capturar_densidad_282.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-densidad-282.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/densidad-282/README.md"
        ).read_text(encoding="utf-8")
        cls.proyecto = (ROOT / "godot/project.godot").read_text(encoding="utf-8")

    def test_captura_las_cuatro_fases_reales_sin_hud(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        for caso, fase in (
            ("oficina", "archivo"),
            ("calle", "trayecto"),
            ("casa", "casa"),
            ("sueno", "sueño"),
        ):
            self.assertIn(f'"id": "{caso}"', self.captura)
            self.assertIn(f'"fase": "{fase}"', self.captura)
        self.assertIn('"hud": false', self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)
        self.assertIn('dia.find_children("*", "CanvasLayer"', self.captura)

    def test_usa_camara_jugable_y_tres_direcciones_por_fase(self):
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.fov = FOV", self.captura)
        self.assertIn("dia._caminante.situar(entrada, mirada)", self.captura)
        self.assertIn("root.size = TAMANO", self.captura)
        self.assertIn('"mirada": 180.0', self.captura)
        self.assertIn('"id": "frente", "offset_mirada": 0.0', self.captura)
        self.assertIn('"id": "izquierda", "offset_mirada": -90.0', self.captura)
        self.assertIn('"id": "derecha", "offset_mirada": 90.0', self.captura)
        self.assertIn('"vistas_por_fase": VISTAS.size()', self.captura)
        self.assertIn(
            'camara.rotation.x = deg_to_rad(float(caso["inclinacion"]))',
            self.captura,
        )

    def test_manifiesto_mide_densidad_sin_convertirla_en_veredicto(self):
        self.assertIn("Densidad.auditar(dia._espacio_actual)", self.captura)
        for campo in (
            '"bultos_modelados"',
            '"bultos_proxy"',
            '"ratio_bultos_modelados"',
            '"mallas_total"',
            '"mallas_caja"',
            '"mallas_planas"',
            '"mallas_array"',
            '"lotes_multimesh"',
            '"interactuables"',
            '"vistas"',
        ):
            self.assertIn(campo, self.captura)
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn("NO deciden", self.captura)

    def test_workflow_publica_doce_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertNotIn("--rendering-method gl_compatibility", self.workflow)
        self.assertIn('renderer/rendering_method="forward_plus"', self.proyecto)
        self.assertIn("for fase in oficina calle casa sueno; do", self.workflow)
        self.assertIn("for vista in frente izquierda derecha; do", self.workflow)
        self.assertIn(
            'test -s "evidencia-densidad-282/${fase}_${vista}.png"',
            self.workflow,
        )
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn('manifest.get("vistas_por_fase") != 3', self.workflow)
        self.assertIn('len(set(hashes)) != 3', self.workflow)
        self.assertIn('caso["mallas_total"] <= 0', self.workflow)

    def test_documentacion_exige_revision_humana(self):
        self.assertIn("sin HUD", self.docs)
        self.assertIn("revisión humana", self.docs.lower())
        self.assertIn("no sustituye", self.docs.lower())
        self.assertIn("boxmesh", self.docs.lower())
        self.assertIn("manifest.json", self.docs)
        self.assertIn("forward+", self.docs.lower())
        self.assertIn("12 capturas", self.docs.lower())


if __name__ == "__main__":
    unittest.main()
