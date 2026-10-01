from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
CICLO = (ROOT / "godot/guion/dia_ciclo_laboral_app.gd").read_text(encoding="utf-8")
CLIMA = (ROOT / "godot/guion/dia_clima_app.gd").read_text(encoding="utf-8")
JORNADA = (ROOT / "godot/guion/dia_jornada_app.gd").read_text(encoding="utf-8")


class DiaCicloLaboral1761Test(unittest.TestCase):
    def test_dia_app_delega_y_queda_por_debajo_de_900_lineas(self):
        self.assertLess(len(DIA.splitlines()), 900)
        self.assertIn("var _ciclo_laboral := DiaCicloLaboralApp.new()", DIA)
        self.assertIn("return _ciclo_laboral.entrada", DIA)
        self.assertNotIn("var _ultimo_recurso:", DIA)
        self.assertNotIn("var _auditorias_nueva_vida:", DIA)

    def test_wrappers_heredables_siguen_en_dia_app(self):
        for firma in (
            "func _abrir_ultimo_recurso_pendiente() -> void:",
            "func _abrir_vuelta() -> void:",
            "func _cerrar_vuelta() -> void:",
            "func _registrar_reincorporacion() -> Dictionary:",
        ):
            self.assertIn(firma, DIA)
        self.assertIn('Callable(self, "_guardar_o_avisar")', DIA)
        self.assertIn('Callable(self, "_reasignar")', DIA)

    def test_helper_posee_estado_temporal_y_reglas_siguen_en_dominios(self):
        for declaracion in (
            "var entrada: Node3D",
            "var ultimo_recurso: UltimoRecursoApp",
            "var auditorias_nueva_vida: AuditoriasNuevaVidaApp",
        ):
            self.assertIn(declaracion, CICLO)
        for autoridad in (
            "Acusacion.canjear_carta_por_vida",
            "Acusacion.aceptar_cese",
            "Auditorias.seleccion_pendiente",
            "Auditorias.resolver_seleccion",
            "ClimaxHastur.reanudar_tras_ultimo_recurso",
            "Sellos.registrar_sello",
            "EntradaCinematica.planos_de",
        ):
            self.assertIn(autoridad, CICLO)
        self.assertNotIn("Partida.new()", CICLO)
        self.assertNotIn("Jornada.nueva(", CICLO)

    def test_contratos_del_canje_cese_y_rollback_siguen_presentes(self):
        self.assertIn('String(resultado.get("resultado", "")) != "canje"', CICLO)
        self.assertIn('parent.get_node_or_null("ClimaxHasturOwnerController")', CICLO)
        self.assertIn('bool(resultado.get("despido", false))', CICLO)
        self.assertIn("reasignar.call()", CICLO)
        self.assertIn("var anterior := Dictionary(estado.get(Auditorias.CLAVE_ESTADO", CICLO)
        self.assertIn("estado[Auditorias.CLAVE_ESTADO] = anterior", CICLO)

    def test_subclases_siguen_consumiento_hooks_y_entrada_compatibles(self):
        self.assertIn("super._abrir_vuelta()", CLIMA)
        self.assertIn("super._cerrar_vuelta()", CLIMA)
        self.assertIn("_entrada != null", CLIMA)
        self.assertIn("_entrada != null", JORNADA)


if __name__ == "__main__":
    unittest.main()
