import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CASOS = ROOT / "godot" / "datos" / "casos.json"
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
PROYECTO = ROOT / "godot" / "project.godot"


class VisorExpedientes513Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        catalogo = json.loads(CASOS.read_text(encoding="utf-8"))
        cls.caso1 = next(caso for caso in catalogo["casos"] if caso["id"] == "caso@1")
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.proyecto = PROYECTO.read_text(encoding="utf-8")

    def test_los_cuatro_folios_del_cierre_siguen_siendo_documentos_ampliados(self):
        esperados = {
            "factura1@1": "F-1999-00231",
            "memo1@1": "MEMO-1999-088",
            "empleado1@1": "EMP-0456",
            "actaContraloria1@1": "ACTA-1999-014",
        }
        registros = {registro["id"]: registro for registro in self.caso1["registros"]}

        self.assertTrue(esperados.keys() <= registros.keys())
        for registro_id, folio in esperados.items():
            registro = registros[registro_id]
            self.assertEqual(registro["folio"], folio)
            self.assertGreaterEqual(
                len(registro["contenido"]),
                300,
                f"{folio}: el corte documental dejó de ser un folio ampliado",
            )

    def test_el_visor_acota_el_cuerpo_y_activa_scroll(self):
        self.assertIn("_documento = RichTextLabel.new()", self.visor)
        self.assertIn("_documento.fit_content = false", self.visor)
        self.assertIn("_documento.scroll_active = true", self.visor)
        self.assertIn(
            "_documento.size_flags_vertical = Control.SIZE_EXPAND_FILL",
            self.visor,
        )

    def test_el_texto_largo_mantiene_tipografia_de_lectura(self):
        self.assertIn(
            '_documento.add_theme_font_override("normal_font", theme.get_font("mono_font", "RichTextLabel"))',
            self.visor,
        )
        self.assertIn(
            '_documento.add_theme_font_size_override("normal_font_size", 15)',
            self.visor,
        )

    def test_el_playtest_documentado_usa_el_viewport_real_del_proyecto(self):
        self.assertIn("window/size/viewport_width=1024", self.proyecto)
        self.assertIn("window/size/viewport_height=680", self.proyecto)


if __name__ == "__main__":
    unittest.main()
