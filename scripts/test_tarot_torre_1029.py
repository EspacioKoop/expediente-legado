import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
RELOJ = ROOT / "godot" / "guion" / "inactividad_prometeo.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_inactividad_prometeo_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "final_alternativo_textos.json"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "pruebas/pruebas_tarot_torre_1029.gd"
RESUMEN = re.compile(r"tarot_torre_1029: (\d+) pasadas, 0 fallos")


def bloque(fuente: str, inicio: str, fin: str) -> str:
    desde = fuente.index(inicio)
    hasta = fuente.index(fin, desde)
    return fuente[desde:hasta]


class TarotTorre1029Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.reloj = RELOJ.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_conserva_el_umbral_y_la_definicion_de_progreso_del_legado(self) -> None:
        self.assertIn("const SEGUNDOS_FINAL := 720.0", self.reloj)
        firma = bloque(
            self.reloj,
            "static func firma_progreso(",
            "static func desbloquear_logro_final(",
        )
        self.assertIn('"tarot"', firma)
        self.assertIn('"logros"', firma)
        self.assertNotIn('"jornada"', firma)
        self.assertNotIn("Input.", self.reloj)

    def test_cargar_solo_arranca_el_reloj_y_no_concede_tarot(self) -> None:
        ready = bloque(self.controlador, "func _ready()", "func _activar()")
        activar = bloque(self.controlador, "func _activar()", "func _process(")
        self.assertIn("set_process(false)", ready)
        self.assertIn("dia.ready.connect(_activar", ready)
        self.assertIn("_reloj.iniciar", activar)
        self.assertNotIn('"la-torre"', ready + activar)
        self.assertNotIn("desbloquear_carta_en_estado", ready + activar)

    def test_el_evento_real_usa_frontera_mundo_y_guardado(self) -> None:
        evento = bloque(
            self.controlador,
            "func _mostrar_final(",
            "func _guardar_evento(",
        )
        torre = evento.index(
            'Prometeo.desbloquear_carta_en_estado(estado, "la-torre")'
        )
        mundo = evento.index("Prometeo.sincronizar_tarot_mundo")
        guardar = evento.index("_guardar_evento")
        self.assertLess(torre, mundo)
        self.assertLess(mundo, guardar)
        self.assertIn("InactividadPrometeo.desbloquear_logro_final", evento)

    def test_copy_visible_vive_fuera_del_controlador(self) -> None:
        for texto in (
            "Final alternativo",
            "El sistema ha aprendido a hablar.",
            "Aceptar la sentencia",
        ):
            self.assertIn(texto, self.textos)
            self.assertNotIn(texto, self.controlador)
        self.assertIn(
            'const RUTA_TEXTOS := "res://datos/final_alternativo_textos.json"',
            self.controlador,
        )

    def test_dia_monta_el_controller_sin_reemplazar_la_raiz(self) -> None:
        self.assertIn(
            'path="res://guion/dia_inactividad_prometeo_app.gd"',
            self.escena,
        )
        self.assertIn('name="InactividadPrometeoController"', self.escena)
        self.assertIn(
            'path="res://guion/dia_clima_app.gd" id="1"',
            self.escena,
        )

    def test_contrato_ejecutable_en_godot(self) -> None:
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
        self.assertIsNotNone(RESUMEN.search(resultado.stdout), resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
