import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "godot" / "guion" / "dia_incidente_impresora_app.gd"
PRUEBA = "res://pruebas/pruebas_incidente_impresora_runtime_1768.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class IncidenteImpresoraRuntime1768Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = CONTROLLER.read_text(encoding="utf-8")

    def test_reutiliza_modelo_y_publica_evento_canonico(self):
        self.assertIn("IncidenteImpresoraOficina.programacion(", self.fuente)
        self.assertIn("IncidenteImpresoraOficina.nuevo(", self.fuente)
        self.assertIn("IncidenteImpresoraOficina.transicionar(", self.fuente)
        self.assertIn("IncidenteImpresoraOficina.EVENTO", self.fuente)
        self.assertIn('jornada["eventos"] = eventos', self.fuente)

    def test_estado_es_diario_y_se_reconstruye(self):
        self.assertIn('CLAVE_ESTADO := "incidente_impresora"', self.fuente)
        self.assertIn('jornada[CLAVE_ESTADO] = estado', self.fuente)
        self.assertIn('int(estado.get("dia", -1))', self.fuente)
        self.assertIn('int(estado.get("vuelta", -1))', self.fuente)
        self.assertIn("_limpiar_estado_obsoleto", self.fuente)

    def test_prop_fisico_usa_interaccion_comun(self):
        self.assertIn("Interactuable3D.new()", self.fuente)
        self.assertIn("CollisionShape3D.new()", self.fuente)
        self.assertIn("Bandeja", self.fuente)
        self.assertIn("PapelAtascado", self.fuente)
        for verbo in ("EXAMINAR", "ABRIR", "COGER", "CERRAR"):
            self.assertIn(f"Interactuable3D.Verbo.{verbo}", self.fuente)

    def test_no_consume_economia_ni_acciones(self):
        for llamada in (
            "Jornada.gastar_accion",
            "Jornada.gastar(",
            "Jornada.avanzar_reloj",
            "Partida.guardar",
        ):
            self.assertNotIn(llamada, self.fuente)
        self.assertNotIn('jornada["acciones"] =', self.fuente)
        self.assertNotIn("dinero", self.fuente.lower())

    def test_no_toca_escena_compartida(self):
        self.assertNotIn("dia.tscn", self.fuente)
        self.assertNotIn("PackedScene", self.fuente)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
