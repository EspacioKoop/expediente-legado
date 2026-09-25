"""Contrato de evidencia reproducible para el gate visual de #399."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaMateriales399Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (ROOT / "godot/pruebas/capturar_materiales_399.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-materiales-399.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/materiales-399/README.md"
        ).read_text(encoding="utf-8")

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

    def test_usa_camara_del_jugador_y_encuadre_reproducible(self):
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.fov = FOV", self.captura)
        self.assertIn('dia._caminante.situar(entrada, mirada)', self.captura)
        self.assertIn("root.size = TAMANO", self.captura)
        self.assertGreaterEqual(self.captura.count('"mirada": 0.0'), 3)
        self.assertIn('"mirada": 180.0', self.captura)
        self.assertIn('camara.rotation.x = deg_to_rad(float(caso["inclinacion"]))', self.captura)
        self.assertIn('"mirada": float(caso["mirada"])', self.captura)

    def test_manifiesto_registra_el_material_que_realmente_se_renderiza(self):
        for campo in (
            '"textura_suelo"',
            '"textura_muro"',
            '"escala_textura"',
            '"contraste_textura"',
            '"preservar_detalle_textura"',
            '"materiales_detalle"',
            '"deformacion_textura"',
        ):
            self.assertIn(campo, self.captura)
        self.assertIn('dia._espacio_actual.get("contraste_textura", 1.0)', self.captura)
        self.assertIn(
            'material.get_shader_parameter("preservar_detalle_textura")',
            self.captura,
        )

    def test_compone_una_comparativa_2x2_sin_re_renderizar(self):
        self.assertIn('"comparativa": "comparativa.png"', self.captura)
        self.assertIn(
            '"orden_comparativa": ["oficina", "calle", "casa", "sueno"]',
            self.captura,
        )
        self.assertIn("capturas_comparativa.append", self.captura)
        self.assertIn("func _guardar_comparativa(", self.captura)
        self.assertIn("Image.create_empty", self.captura)
        self.assertIn("miniatura.resize(ancho, alto", self.captura)
        self.assertIn("comparativa.blit_rect(", self.captura)
        self.assertIn('"sha256_comparativa"', self.captura)

    def test_workflow_publica_png_manifiesto_comparativa_y_resumen(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("for captura in oficina calle casa sueno; do", self.workflow)
        self.assertIn('test -s "evidencia-materiales-399/${captura}.png"', self.workflow)
        self.assertIn("comparativa.png", self.workflow)
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("resumen.md", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("len(set(hashes)) != 4", self.workflow)

    def test_documentacion_no_finge_automatizar_el_juicio_visual(self):
        self.assertIn("revisión", self.docs.lower())
        self.assertIn("humana", self.docs.lower())
        self.assertIn("sin HUD", self.docs)
        self.assertIn("comparativa 2×2", self.docs.lower())
        self.assertIn("resumen.md", self.docs)
        self.assertIn("no sustituye", self.docs.lower())


if __name__ == "__main__":
    unittest.main()
