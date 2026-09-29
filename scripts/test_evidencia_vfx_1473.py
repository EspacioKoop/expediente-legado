"""Contrato estático de evidencia reproducible para #1473."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaVfx1473Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (
            ROOT / "godot/pruebas/capturar_vfx_1473.gd"
        ).read_text(encoding="utf-8")
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-vfx-1473.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/vfx-1473/README.md"
        ).read_text(encoding="utf-8")
        cls.proyecto = (ROOT / "godot/project.godot").read_text(encoding="utf-8")

    def test_recorre_cuatro_fases_reales_con_camara_jugable(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        for caso, fase in (
            ("oficina", "archivo"),
            ("calle", "trayecto"),
            ("casa", "casa"),
            ("sueno", "sueño"),
        ):
            self.assertIn(f'"id": "{caso}"', self.captura)
            self.assertIn(f'"fase": "{fase}"', self.captura)
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("dia._caminante.situar(entrada", self.captura)
        self.assertIn('"camara": "jugable"', self.captura)
        self.assertIn('"hud": false', self.captura)
        self.assertIn('TranslationServer.set_locale("es")', self.captura)

    def test_genera_ab_y_desmonta_solo_la_capa_vfx(self):
        self.assertIn('"%s_activo.png"', self.captura)
        self.assertIn('"%s_inactivo.png"', self.captura)
        self.assertIn("_desmontar_vfx_ligeros(dia._mundo)", self.captura)
        self.assertIn("EfectosLigeros.NOMBRE", self.captura)
        self.assertIn("EfectosLigeros.NOMBRE_VAPOR", self.captura)
        self.assertIn('cristal.get_node_or_null("Gotas")', self.captura)
        self.assertNotIn("reduccion_movimiento", self.captura)

    def test_mide_presupuesto_y_tiempo_sin_autoaprobar(self):
        for campo in (
            '"muestras_frames"',
            '"ms_frame_activo"',
            '"ms_frame_inactivo"',
            '"delta_ms_frame"',
            '"particulas_vfx_activo"',
            '"particulas_vfx_inactivo"',
            '"emisores_vfx_activo"',
            '"superficies_vfx_activo"',
        ):
            self.assertIn(campo, self.captura)
        self.assertIn("Time.get_ticks_usec()", self.captura)
        self.assertIn("await RenderingServer.frame_post_draw", self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)
        self.assertIn(
            '"comparacion_rendimiento": "diagnostico_misma_ejecucion_sin_umbral"',
            self.captura,
        )

    def test_workflow_usa_forward_plus_y_publica_artifact(self):
        self.assertIn('renderer/rendering_method="forward_plus"', self.proyecto)
        self.assertIn("xvfb-run -a godot4 --path godot", self.workflow)
        self.assertNotIn("--rendering-method gl_compatibility", self.workflow)
        self.assertIn("for fase in oficina calle casa sueno; do", self.workflow)
        self.assertIn('test -s "evidencia-vfx-1473/${fase}_activo.png"', self.workflow)
        self.assertIn('test -s "evidencia-vfx-1473/${fase}_inactivo.png"', self.workflow)
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@", self.workflow)
        self.assertIn("evidencia-vfx-1473-${{ github.sha }}", self.workflow)
        self.assertIn('manifest.get("renderer") != "forward_plus"', self.workflow)
        self.assertIn('manifest.get("veredicto_automatico") is not False', self.workflow)
        self.assertIn('sum(c["particulas_vfx_activo"] for c in casos.values()) <= 0', self.workflow)
        self.assertIn('c["particulas_vfx_inactivo"] != 0', self.workflow)

    def test_documentacion_separa_diagnostico_de_veredicto(self):
        texto = self.docs.lower()
        self.assertIn("8 capturas", texto)
        self.assertIn("forward+", texto)
        self.assertIn("revisión humana", texto)
        self.assertIn("misma ejecución", texto)
        self.assertIn("no es un benchmark absoluto", texto)
        self.assertIn("no autoaprueba", texto)
        self.assertIn("manifest.json", self.docs)


if __name__ == "__main__":
    unittest.main()
