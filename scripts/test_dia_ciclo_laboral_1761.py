from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
CICLO = ROOT / "godot" / "guion" / "dia_ciclo_laboral_app.gd"


class DiaCicloLaboral1761Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.ciclo = CICLO.read_text(encoding="utf-8")

    def test_dia_recupera_margen_y_delega_el_ciclo_laboral(self):
        self.assertLess(len(self.dia.splitlines()), 900)
        self.assertIn("DiaCicloLaboralApp.new()", self.dia)
        self.assertIn("_ciclo_laboral.configurar(", self.dia)
        self.assertIn("_ciclo_laboral.reasignacion_solicitada.connect(_reasignar)", self.dia)
        self.assertIn("_ciclo_laboral.abrir_ultimo_recurso_pendiente(jornada)", self.dia)
        self.assertIn("_ciclo_laboral.abrir_vuelta(jornada)", self.dia)

    def test_estado_temporal_del_ciclo_ya_no_vive_en_dia(self):
        for nombre in (
            "var _entrada: Node3D",
            "var _ultimo_recurso: UltimoRecursoApp",
            "var _auditorias_nueva_vida: AuditoriasNuevaVidaApp",
        ):
            self.assertNotIn(nombre, self.dia)
            self.assertIn(nombre, self.ciclo)

    def test_reglas_siguen_en_dominios_existentes(self):
        for llamada in (
            "Acusacion.canjear_carta_por_vida",
            "Acusacion.aceptar_cese",
            "Auditorias.resolver_seleccion",
            "Sellos.registrar_sello",
            "ClimaxHastur.reanudar_tras_ultimo_recurso",
            "EntradaCinematica.planos_de",
        ):
            self.assertIn(llamada, self.ciclo)
            self.assertNotIn(llamada, self.dia)

    def test_reasignacion_vuelve_al_orquestador(self):
        self.assertIn("signal reasignacion_solicitada", self.ciclo)
        self.assertIn("reasignacion_solicitada.emit()", self.ciclo)
        reasignar = self.dia.split("func _reasignar() -> void:", 1)[1].split(
            "func _refrescar_rotulos", 1
        )[0]
        self.assertIn('_entrar_en(jornada["fase"])', reasignar)
        self.assertIn("_ciclo_laboral.abrir_vuelta(jornada)", reasignar)


if __name__ == "__main__":
    unittest.main()
