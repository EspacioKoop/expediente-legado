import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot" / "guion" / "visor_metadatos_app.gd"
CATALOGO = ROOT / "godot" / "datos" / "analisis_documental.json"
CASOS = ROOT / "godot" / "datos" / "casos.json"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class AnalisisDocumental951Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        cls.casos = json.loads(CASOS.read_text(encoding="utf-8"))
        cls.textos = TEXTOS.read_text(encoding="utf-8")
        cls.registros = {
            registro["id"]: registro
            for caso in cls.casos["casos"]
            for registro in caso.get("registros", [])
        }

    def test_el_modo_vive_en_la_capa_real_de_metadatos(self):
        self.assertIn('RUTA_ANALISIS_DOCUMENTAL := "res://datos/analisis_documental.json"', self.visor)
        self.assertIn('_analizar_documento.text = tr("VISOR_ANALISIS_951_ACCION")', self.visor)
        self.assertIn("_analizar_documento.pressed.connect(_analizar_documento_actual)", self.visor)
        self.assertIn("_resultado_analisis.visible = true", self.visor)

    def test_catalogo_solo_referencia_folios_reales_y_textos_localizados(self):
        ids_detalle = set()
        for registro_id, detalles in self.catalogo.items():
            self.assertIn(registro_id, self.registros)
            self.assertIsInstance(detalles, list)
            for detalle in detalles:
                detalle_id = detalle.get("id", "")
                clave = detalle.get("texto", "")
                self.assertTrue(detalle_id)
                self.assertNotIn(detalle_id, ids_detalle)
                ids_detalle.add(detalle_id)
                self.assertRegex(self.textos, rf"(?m)^{re.escape(clave)},")

    def test_analizar_no_guarda_ni_descubre_pistas(self):
        inicio = self.visor.index("func _analizar_documento_actual()")
        fin = self.visor.index("\n\nstatic func _cargar_catalogo_analisis_documental()", inicio)
        metodo = self.visor[inicio:fin]
        for token in (
            "_guardar_o_avisar",
            "pistas_descubiertas",
            "descubiertas.append",
            "Jornada.gastar",
            "partida.estado",
        ):
            self.assertNotIn(token, metodo)

    def test_hallazgos_iniciales_estan_respaldados_por_el_canon(self):
        factura = self.registros["factura4@4"]
        self.assertIn("amarillo", factura["contenido"])
        self.assertIn("RFC", factura["contenido"])
        self.assertIn("en blanco", factura["contenido"])

        acta = self.registros["acta6@6"]
        self.assertIn("amarillo", acta["contenido"])
        self.assertIn("no notarial", acta["contenido"])

        circular = self.registros["circular6@6"]
        self.assertIsNone(circular["fecha"])

        memo = self.registros["memo5@5"]
        self.assertTrue(memo["folio"].startswith("MEMO-1978-"))
        self.assertTrue(str(memo["fecha"]).startswith("2007-"))

    def test_hay_salida_neutra_para_folios_sin_catalogar(self):
        self.assertIn('tr("VISOR_ANALISIS_951_SIN_HALLAZGOS")', self.visor)
        self.assertIn("No se detectan anomalías catalogadas", self.textos)


if __name__ == "__main__":
    unittest.main()
