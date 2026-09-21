import csv
import json
import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "detalles_meticulosos.json"
CASOS = ROOT / "godot" / "datos" / "casos.json"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
CONTRATO = ROOT / "godot" / "guion" / "detalles_meticulosos.gd"
METICULOSIDAD = ROOT / "godot" / "guion" / "meticulosidad.gd"
VISOR = ROOT / "godot" / "guion" / "visor_metadatos_app.gd"
SMOKE = "pruebas/issue_961_detalles_smoke.gd"


class DetallesMeticulosidad961Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        cls.casos = json.loads(CASOS.read_text(encoding="utf-8"))["casos"]
        cls.contrato = CONTRATO.read_text(encoding="utf-8")
        cls.meticulosidad = METICULOSIDAD.read_text(encoding="utf-8")
        cls.visor = VISOR.read_text(encoding="utf-8")

    def test_catalogo_apunta_a_documentos_y_textos_reales(self):
        registros = {
            registro["id"]
            for caso in self.casos
            for registro in caso["registros"]
        }
        with TEXTOS.open(encoding="utf-8", newline="") as archivo:
            claves = {fila["clave"] for fila in csv.DictReader(archivo)}

        self.assertEqual(set(self.catalogo), {"memo1@1", "oficio2@2"})
        for registro_id, detalles in self.catalogo.items():
            self.assertIn(registro_id, registros)
            for detalle in detalles:
                self.assertIn(detalle["texto"], claves)
                self.assertIn(
                    detalle["motivo"],
                    {"fecha", "margen", "folio", "relacion", "relectura"},
                )

    def test_el_visor_oculta_el_detalle_hasta_observarlo(self):
        self.assertIn("var _detalle_meticuloso: Label", self.visor)
        self.assertIn("_detalle_meticuloso.visible = false", self.visor)
        self.assertIn("MeticulosidadEstado.motivos_documento", self.visor)
        self.assertIn("DetallesMeticulososEstado.detalles_para", self.visor)
        self.assertIn('tr("VISOR_DETALLE_961_OBSERVACION")', self.visor)

    def test_el_corte_no_es_un_segundo_sistema_de_pistas(self):
        combinado = self.contrato + self.meticulosidad + self.visor
        for prohibido in (
            "descubiertas.append",
            "pistas_descubiertas",
            "Acusacion.acusar",
            "SuenoObjetivos",
            "objetivos_requeridos",
        ):
            self.assertNotIn(prohibido, combinado)

    def test_el_estado_conserva_motivos_por_documento(self):
        self.assertIn('ficha["motivos"] = motivos_documento', self.meticulosidad)
        self.assertIn("static func motivos_documento", self.meticulosidad)
        self.assertIn("eventos.sort()", self.meticulosidad)

    def test_smoke_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                SMOKE,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("issue_961_detalles:", resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
