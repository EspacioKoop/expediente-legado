"""#116: QA completa fuera de release; manual limitado y desbloqueable en release."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
CONSOLA_QA = GODOT / "debug" / "consola_depuracion.gd"
CONSOLA_RELEASE = GODOT / "guion" / "consola_trucos_release.gd"
CARGADOR = GODOT / "guion" / "cargador_consola_depuracion.gd"
CONSOLA_ANTIGUA = GODOT / "depuracion" / "consola_depuracion.gd"
PROYECTO = GODOT / "project.godot"
PRESETS = GODOT / "export_presets.cfg"
CLIMA = GODOT / "guion" / "dia_clima_app.gd"


class ConsolaDepuracionTest(unittest.TestCase):
    def setUp(self):
        self.qa = CONSOLA_QA.read_text(encoding="utf-8")
        self.release = CONSOLA_RELEASE.read_text(encoding="utf-8")
        self.cargador = CARGADOR.read_text(encoding="utf-8")

    def test_el_autoload_separa_qa_y_release(self):
        proyecto = PROYECTO.read_text(encoding="utf-8")
        self.assertIn('ConsolaDepuracion="*res://guion/cargador_consola_depuracion.gd"', proyecto)
        self.assertIn("OS.is_debug_build()", self.cargador)
        self.assertIn('OS.has_feature("qa_tools")', self.cargador)
        self.assertIn('res://debug/consola_depuracion.gd', self.cargador)
        self.assertIn('res://guion/consola_trucos_release.gd', self.cargador)
        self.assertNotIn("func ejecutar(", self.cargador)

    def test_la_implementacion_qa_vive_solo_bajo_debug(self):
        self.assertTrue(CONSOLA_QA.is_file())
        self.assertFalse(CONSOLA_ANTIGUA.exists())

    def test_qa_se_abre_con_la_tecla_de_la_izquierda_del_uno(self):
        self.assertIn("KEY_QUOTELEFT", self.qa)
        self.assertIn('"º"', self.qa)

    def test_la_exportacion_publica_excluye_la_consola_qa(self):
        filtros = re.findall(r'exclude_filter="([^"]*)"', PRESETS.read_text(encoding="utf-8"))
        self.assertGreaterEqual(len(filtros), 2)
        for filtro in filtros[:2]:
            self.assertIn("debug/**", {p.strip() for p in filtro.split(",")})

    def test_qa_conserva_los_comandos_de_playtest(self):
        for comando in (
            "fase",
            "sala",
            "dia",
            "dinero",
            "pistas",
            "gato",
            "clima",
            "desatascar",
            "dibujo",
        ):
            self.assertIn(f'"{comando}":', self.qa)
        self.assertIn('res://debug/dibujo_3d.gd', self.qa)

    def test_release_exige_desbloqueo_y_solo_tiene_utilidades_seguras(self):
        self.assertIn("TiendaVideojuegos.consola_trucos_desbloqueada()", self.release)
        for comando in ("clima", "desatascar", "portatil", "diagnostico"):
            self.assertIn(f'"{comando}":', self.release)
        for handler in ("fase", "sala", "dia", "dinero", "pistas", "gato", "dibujo"):
            self.assertNotIn(f"func _cmd_{handler}(", self.release)
        self.assertNotIn("dibujo_3d.gd", self.release)
        self.assertNotIn('_entrar_en("casa")', self.release)
        self.assertIn('dia.jornada["fase"] != "casa"', self.release)

    def test_release_expone_manifiesto_reproducible(self):
        self.assertIn("Azar.manifiesto_en_texto(dia.partida.estado)", self.release)

    def test_el_clima_forzado_llega_al_dia(self):
        self.assertIn('jornada.get("clima_forzado", "")', CLIMA.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
