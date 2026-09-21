"""Contrato estático del gate conjunto de #672, #674 y #677."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaVida1998Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (
            ROOT / "godot/pruebas/capturar_vida_1998_672_674_677.gd"
        ).read_text(encoding="utf-8")
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-vida-1998.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/vida-1998/README.md"
        ).read_text(encoding="utf-8")

    def test_cubre_los_cuatro_encuadres_del_gate(self):
        for caso in (
            "buzon_portal",
            "publicacion_encontrable",
            "acumulacion_tres_fuentes",
            "calendario_nevera",
        ):
            self.assertIn(f'"id": "{caso}"', self.captura)
        self.assertIn('"issues": [672, 674, 677]', self.captura)

    def test_prepara_tres_productores_reales_sin_estado_paralelo(self):
        self.assertIn("ComercioBarrio.comprar", self.captura)
        self.assertIn("CorreoPostal.recoger", self.captura)
        self.assertIn("PublicacionesEncontrables3D.objeto_inventario", self.captura)
        self.assertGreaterEqual(self.captura.count("Inventario.guardar_en_casa"), 2)
        self.assertIn('"comercio_barrio"', self.captura)
        self.assertIn('"correo_postal"', self.captura)
        self.assertIn("PublicacionesEncontrables3D.ORIGEN", self.captura)
        self.assertIn("Inventario.HOME_STORAGE", self.captura)

    def test_usa_escena_y_camara_jugables_sin_hud(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        self.assertIn('dia._entrar_en("trayecto")', self.captura)
        self.assertIn('dia._entrar_en("casa")', self.captura)
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.look_at", self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)

    def test_exige_nodos_reales_de_los_tres_verticales(self):
        for nodo in (
            "BuzonPostal",
            "PublicacionEncontrable_",
            "AcumulacionCasa",
            "EstanteriaComprasCasa",
            "NOMBRE_IMAN_CALENDARIO",
        ):
            self.assertIn(nodo, self.captura)

    def test_workflow_publica_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn(
            "for captura in buzon_portal publicacion_encontrable "
            "acumulacion_tres_fuentes calendario_nevera; do",
            self.workflow,
        )
        self.assertIn("evidencia-vida-1998/manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-vida-1998-${{ github.sha }}", self.workflow)
        self.assertIn("len(set(hashes)) != 4", self.workflow)
        self.assertIn("len(set(origenes)) != 3", self.workflow)

    def test_documentacion_exige_revision_humana_y_controles(self):
        texto = self.docs.lower()
        self.assertIn("revisión humana", texto)
        self.assertIn("pass/fail", texto)
        self.assertIn("teclado", texto)
        self.assertIn("mando", texto)
        self.assertIn("reduccion_movimiento", texto)
        self.assertIn("no cierra automáticamente", texto)


if __name__ == "__main__":
    unittest.main()
