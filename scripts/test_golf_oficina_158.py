import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "godot" / "guion" / "dia_golf_pasillo_app.gd"
PARTIDA = ROOT / "godot" / "guion" / "golf_partida_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_golf_oficina_158.gd"


class GolfOficina158Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.partida = PARTIDA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_reutiliza_vertical_y_ranking_existentes(self):
        self.assertIn('preload("res://escenas/golf_partida_standalone.tscn")', self.controller)
        self.assertIn("RankingGolf.registrar_local(", self.controller)
        self.assertIn("GolfPartidaApp.JUGADOR", self.controller)
        self.assertNotIn("RankingGolfOnline", self.controller)
        self.assertNotIn("HTTPRequest", self.controller)

    def test_oferta_es_opcional_no_diaria_y_persistible(self):
        self.assertIn("PERIODO_DIAS := 4", self.controller)
        self.assertIn("DIA_INICIAL := 3", self.controller)
        self.assertIn('CLAVE_ULTIMO_DIA := "golf_pasillo_ultimo_dia"', self.controller)
        self.assertIn("static func disponible(jornada: Dictionary)", self.controller)
        self.assertIn("static func marcar_jugado(jornada: Dictionary)", self.controller)
        self.assertIn('dia.call("_guardar_o_avisar", "")', self.controller)
        for forbidden in ("Jornada.gastar_accion", "Economia.", "Sellos.", "Acusacion."):
            self.assertNotIn(forbidden, self.controller)

    def test_integracion_suspende_y_restaura_presentacion(self):
        self.assertIn("_mundo_sesion.visible = false", self.controller)
        self.assertIn("Node.PROCESS_MODE_DISABLED", self.controller)
        self.assertIn("set_process_unhandled_input(false)", self.controller)
        self.assertIn("_restaurar_presentacion()", self.controller)
        self.assertIn('dia.set_meta("ultimo_resultado_golf"', self.controller)

    def test_abandono_no_se_convierte_en_ranking(self):
        bloque = self.controller.split("func _cerrar_sesion", 1)[1].split("\n\nfunc ", 1)[0]
        self.assertIn('if bool(resultado.get("completa", false)):', bloque)
        self.assertIn("_registrar_ranking_local", bloque)
        self.assertIn("Golf.abandonar(estado)", self.partida)

    def test_dia_monta_el_controller(self):
        self.assertIn('path="res://guion/dia_golf_pasillo_app.gd"', self.dia)
        self.assertIn('[node name="GolfPasilloController" type="Node" parent="."]', self.dia)

    def test_regresion_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                str(PRUEBA.relative_to(ROOT / "godot")),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
