import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
UTILERIA = ROOT / "godot" / "guion" / "oficina_utileria.gd"
CAFE = ROOT / "godot" / "guion" / "maquina_cafe_interactiva_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_oficina_utileria_app.gd"
DRESSING_PREVIO = ROOT / "godot" / "guion" / "dia_dressing_cc0_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "pruebas/pruebas_maquina_cafe.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class OficinaUtileriaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.cafe = CAFE.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.dressing_previo = DRESSING_PREVIO.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_controller_se_conecta_sin_sustituir_la_raiz(self):
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)
        self.assertIn('path="res://guion/dia_oficina_utileria_app.gd" id="7"', self.escena)
        self.assertIn('[node name="OficinaUtileriaController"', self.escena)
        self.assertIn('String(dia.jornada.get("fase", "")) == "archivo"', self.controlador)
        self.assertIn("OficinaUtileria.montar(mundo, Jornada.PRECIO_CAFE)", self.controlador)
        self.assertNotIn('== "casa"', self.controlador)
        self.assertNotIn('== "trayecto"', self.controlador)
        self.assertNotIn('== "sueño"', self.controlador)

    def test_cuatro_puestos_reciben_contexto_y_variacion(self):
        for nombre in (
            "PuestoUtileria%d",
            '"Teclado"',
            '"CableTeclado"',
            '"TelefonoBase"',
            '"Auricular"',
            '"BandejaEntrada"',
            '"TazaPuesto"',
        ):
            self.assertIn(nombre, self.utileria)
        self.assertEqual(self.utileria.count("Vector3(-4.0, 0.0,"), 2)
        self.assertEqual(self.utileria.count("Vector3(1.0, 0.0,"), 2)
        self.assertIn("indice % 2", self.utileria)

    def test_no_duplica_crt_del_primer_corte(self):
        self.assertIn('"MonitorPuestoC"', self.dressing_previo)
        self.assertIn('"MonitorPuestoD"', self.dressing_previo)
        self.assertNotIn("computerScreen", self.utileria)
        self.assertNotIn("MonitorCRT", self.utileria)
        self.assertNotIn("Modelos.mueble", self.utileria)

    def test_cafe_reutiliza_interaccion_y_feedback_visible(self):
        self.assertIn("extends Interactuable3D", self.cafe)
        self.assertIn("verbo = Verbo.USAR", self.cafe)
        self.assertIn('nombre_objeto = "máquina de café"', self.cafe)
        self.assertIn("CollisionShape3D.new()", self.cafe)
        self.assertIn('taza.name = "TazaServida"', self.cafe)
        self.assertIn('piloto.name = "PilotoCafe"', self.cafe)
        self.assertIn("_taza.visible = _taza_visible", self.cafe)
        self.assertIn("emission_enabled = _taza_visible", self.cafe)
        self.assertIn('maquina.name = "MaquinaCafeInteractuable"', self.utileria)
        self.assertIn("maquina.configurar(precio_cafe)", self.utileria)

    def test_maquina_y_utileria_no_deciden_economia(self):
        combinado = self.utileria + self.cafe
        for termino in (
            "Partida",
            "Jornada",
            "inventario",
            'jornada["dinero"]',
            "guardar(",
            "FileAccess",
            "InputEventKey",
            "KEY_",
        ):
            self.assertNotIn(termino, combinado)

    def test_controller_es_el_unico_dueno_del_cafe_economico(self):
        self.assertIn("Jornada.tomar_cafe(dia.jornada, Jornada.PRECIO_CAFE)", self.controlador)
        self.assertIn("Jornada.BONUS_ACCIONES_MAX_POR_DIA", self.controlador)
        self.assertIn("maquina.servir()", self.controlador)
        self.assertIn("maquina.retirar_taza()", self.controlador)
        self.assertIn("maquina.activado.is_connected(callback)", self.controlador)
        self.assertIn('dia._guardar_o_avisar("")', self.controlador)
        self.assertNotIn('dia.jornada["dinero"] -=', self.controlador)
        self.assertNotIn('dia.jornada["acciones"] +=', self.controlador)

    def test_no_introduce_assets_externos(self):
        combinado = self.utileria + self.cafe + self.controlador
        for termino in ("load(", "preload(", ".glb", ".png", ".jpg"):
            self.assertNotIn(termino, combinado)

    def test_corte_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()

        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 28, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
