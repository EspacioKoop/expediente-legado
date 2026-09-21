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
        cls.registros = {registro["id"]: registro for registro in cls.caso1["registros"]}
        cls.pistas = {pista["id"]: pista for pista in cls.caso1["pistas"]}
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.proyecto = PROYECTO.read_text(encoding="utf-8")

    def test_los_cuatro_folios_del_cierre_siguen_siendo_documentos_ampliados(self):
        esperados = {
            "factura1@1": "F-1999-00231",
            "memo1@1": "MEMO-1999-088",
            "empleado1@1": "EMP-0456",
            "actaContraloria1@1": "ACTA-1999-014",
        }

        self.assertTrue(esperados.keys() <= self.registros.keys())
        for registro_id, folio in esperados.items():
            registro = self.registros[registro_id]
            self.assertEqual(registro["folio"], folio)
            self.assertGreaterEqual(
                len(registro["contenido"]),
                300,
                f"{folio}: el corte documental dejó de ser un folio ampliado",
            )

    def test_las_frases_gatillo_del_caso_1_siguen_en_su_documento(self):
        esperadas = {
            "pista1@1": ("memo1@1", "sin revisión previa"),
            "pista2@1": ("empleado1@1", "cuatro días después del cierre de caja"),
        }

        for pista_id, (registro_id, frase) in esperadas.items():
            pista = self.pistas[pista_id]
            self.assertEqual(pista["registroOrigen"], registro_id)
            self.assertEqual(pista["fraseGatillo"], frase)
            self.assertIn(frase, self.registros[registro_id]["contenido"])

    def test_las_conclusiones_documentales_siguen_exigiendo_relacionar_dos_folios(self):
        relaciones = {
            "pista20@1": ("factura1@1", "actaContraloria1@1"),
            "pista28@1": ("memo1@1", "empleado1@1"),
        }

        for pista_id, origenes in relaciones.items():
            pista = self.pistas[pista_id]
            self.assertEqual(
                (pista["registroOrigen"], pista["registroOrigen2"]),
                origenes,
            )
            self.assertNotIn(
                "fraseGatillo",
                pista,
                f"{pista_id}: una relación entre documentos no debe descubrirse al leer un solo folio",
            )

    def test_el_peritaje_permanece_como_evidencia_cruzada_no_como_gatillo(self):
        self.assertIn("peritaje", self.registros["memo1@1"]["contenido"].lower())
        self.assertIn("peritaje", self.registros["empleado1@1"]["contenido"].lower())
        self.assertEqual(
            {
                self.pistas["pista28@1"]["registroOrigen"],
                self.pistas["pista28@1"]["registroOrigen2"],
            },
            {"memo1@1", "empleado1@1"},
        )
        self.assertNotIn("fraseGatillo", self.pistas["pista28@1"])

    def test_el_visor_acota_el_cuerpo_y_activa_scroll(self):
        self.assertIn("_documento = RichTextLabel.new()", self.visor)
        self.assertIn("_documento.fit_content = false", self.visor)
        self.assertIn("_documento.scroll_active = true", self.visor)
        self.assertIn(
            "_documento.size_flags_vertical = Control.SIZE_EXPAND_FILL",
            self.visor,
        )

    def test_releer_un_folio_largo_no_vuelve_a_consumir_lectura(self):
        self.assertIn(
            'var ya_visto: bool = jornada["leido_hoy"].has(registro["folio"])',
            self.visor,
        )
        self.assertIn(
            'if not ya_visto and not Acusacion.esta_cerrado(partida.estado, caso["id"]):',
            self.visor,
        )
        self.assertIn("if not ya_visto:\n\t\tJornada.anotar_lectura", self.visor)

    def test_el_texto_largo_usa_el_rol_documental_y_no_mono(self):
        self.assertIn(
            '"normal_font", theme.get_font("document_font", "RichTextLabel")',
            self.visor,
        )
        self.assertNotIn(
            '"normal_font", theme.get_font("mono_font", "RichTextLabel")',
            self.visor,
        )
        self.assertIn(
            '_documento.add_theme_font_size_override("normal_font_size", 15)',
            self.visor,
        )

    def test_la_barra_manual_del_visor_usa_el_rol_de_titulo(self):
        self.assertIn(
            'titulo.add_theme_font_override("font", theme.get_font("title_font", "Label"))',
            self.visor,
        )

    def test_el_playtest_documentado_usa_el_viewport_real_del_proyecto(self):
        self.assertIn("window/size/viewport_width=1920", self.proyecto)
        self.assertIn("window/size/viewport_height=1080", self.proyecto)


if __name__ == "__main__":
    unittest.main()
