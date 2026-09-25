import importlib.util
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURAR = ROOT / "godot" / "pruebas" / "capturar.gd"
DOC = ROOT / "docs" / "assets" / "tarot-major-arcana.md"
PREPARAR = ROOT / "scripts" / "preparar_validacion_tarot_645.py"


def _cargar_preparador():
    spec = importlib.util.spec_from_file_location("preparar_validacion_tarot_645", PREPARAR)
    assert spec is not None and spec.loader is not None
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


class CapturaTarot645Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.capturar = CAPTURAR.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_busca_el_folio_en_todos_los_expedientes(self) -> None:
        self.assertIn("for i in escena.contenido.casos.size():", self.capturar)
        self.assertIn('registro.get("folio") == folio_carta', self.capturar)
        self.assertIn("escena._al_elegir_caso(indice_caso)", self.capturar)
        self.assertIn('var registros: Array = escena.caso["registros"]', self.capturar)

    def test_no_toca_partida_real_y_permite_reduccion_de_movimiento(self) -> None:
        self.assertIn('OS.get_environment("XDG_DATA_HOME").is_empty()', self.capturar)
        self.assertIn('modo not in ["normal", "reducido"]', self.capturar)
        self.assertIn('preferencias["reduccion_movimiento"] = true', self.capturar)
        self.assertIn("PreferenciasSiga.guardar(preferencias)", self.capturar)

    def test_preparador_genera_ocultas_y_progreso_aislables(self) -> None:
        modulo = _cargar_preparador()
        with tempfile.TemporaryDirectory() as temporal:
            destino = Path(temporal)
            manifiesto = modulo.preparar(destino, "godot4", ejecutar=False)
            revision = (destino / "revision-humana.md").read_text(encoding="utf-8")
        self.assertEqual(manifiesto["total"], 26)
        self.assertEqual(manifiesto["esperadas"], 26)
        capturas = {entrada["captura"] for entrada in manifiesto["entradas"]}
        self.assertEqual(len(capturas), 26)
        self.assertTrue(all(nombre.startswith("tarot-") for nombre in capturas))
        ocultas = [e for e in manifiesto["entradas"] if e["tipo"] == "oculta"]
        progreso = [e for e in manifiesto["entradas"] if e["tipo"] == "progreso"]
        self.assertEqual(len(ocultas), 24)
        self.assertEqual(len(progreso), 2)
        self.assertEqual(
            {entrada["recorrido"] for entrada in ocultas},
            {"normal", "reducido", "skip"},
        )
        self.assertEqual(
            {entrada["recorrido"] for entrada in progreso},
            {"normal", "reducido"},
        )
        self.assertTrue(all("progreso" in entrada["captura"] for entrada in progreso))
        self.assertTrue(all(entrada["carta"] == "el-mago" for entrada in progreso))
        self.assertTrue(all(entrada["ok"] is None for entrada in manifiesto["entradas"]))
        self.assertIn("# Revisión humana Tarot #645", revision)
        self.assertIn("![la-justicia normal](tarot-la-justicia-normal.png)", revision)
        self.assertIn("![el-mago progreso normal](tarot-el-mago-progreso-normal.png)", revision)
        self.assertEqual(revision.count("Estado técnico: **pendiente**"), 26)

    def test_documenta_las_ocho_cartas_y_no_finge_la_progresion(self) -> None:
        for folio in (
            "ACTA-1999-014",
            "OF-1990-114",
            "MEMO-1993-201",
            "F-1996-00187",
            "ACTA-2007-002",
            "FAX-1996-077",
            "OF-1998-077",
            "ACTA-1998-427B",
        ):
            self.assertIn(folio, self.doc)
        self.assertIn("frontal del plano 2", self.doc)
        self.assertIn("primera pista", self.doc)
        self.assertIn("#1029", self.doc)
        self.assertIn("permanece pendiente", self.doc)
        self.assertIn("revision-humana.md", self.doc)


if __name__ == "__main__":
    unittest.main()
