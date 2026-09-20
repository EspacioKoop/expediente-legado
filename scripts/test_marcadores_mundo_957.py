import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CONTRATO = ROOT / "godot" / "guion" / "marcadores_mundo.gd"
VISUAL = ROOT / "godot" / "guion" / "marcador_mundo_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_marcadores_mundo_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class MarcadoresMundo957Test(unittest.TestCase):
    def test_contrato_persistente_es_acotado_y_json_safe(self):
        codigo = CONTRATO.read_text(encoding="utf-8")

        self.assertIn('const CLAVE := "marcadores_mundo"', codigo)
        self.assertIn("const LIMITE_POR_ZONA := 5", codigo)
        self.assertIn("const MAX_TEXTO := 24", codigo)
        self.assertIn("static func colocar(", codigo)
        self.assertIn("static func eliminar(", codigo)
        self.assertIn("static func eliminar_zona(", codigo)
        self.assertIn('"posicion": _vector_a_lista(posicion)', codigo)
        self.assertIn('"normal": _vector_a_lista(normal_limpia)', codigo)
        self.assertNotIn("FileAccess", codigo)
        self.assertNotIn("Partida.", codigo)

    def test_visual_es_diegetico_y_no_modifica_fisica(self):
        codigo = VISUAL.read_text(encoding="utf-8")

        self.assertIn("class_name MarcadorMundo3D", codigo)
        self.assertIn("extends Node3D", codigo)
        self.assertIn("BoxMesh.new()", codigo)
        self.assertIn("Label3D.new()", codigo)
        self.assertIn("DESPLAZAMIENTO_ESTRES_MAX", codigo)
        self.assertNotIn("CollisionShape3D", codigo)
        self.assertNotIn("StaticBody3D", codigo)
        self.assertNotIn("Area3D", codigo)
        self.assertNotIn("Input.", codigo)

    def test_controller_restaura_sin_secuestrar_input_o_progreso(self):
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        escena = ESCENA.read_text(encoding="utf-8")

        self.assertIn("class_name DiaMarcadoresMundoApp", codigo)
        self.assertIn("MarcadoresMundo.listar(_host.jornada, zona)", codigo)
        self.assertIn('String(_host.jornada.get("fase", ""))', codigo)
        self.assertIn('if _host.has_method("_guardar_o_avisar")', codigo)
        self.assertNotIn("Input.", codigo)
        self.assertNotIn("SuenoObjetivos", codigo)
        self.assertNotIn("Economia.", codigo)

        self.assertIn(
            'path="res://guion/dia_marcadores_mundo_app.gd"',
            escena,
        )
        self.assertIn(
            '[node name="MarcadoresMundoController" type="Node" parent="."]',
            escena,
        )
        self.assertIn('script = ExtResource("1")', escena)
        self.assertIn('script = ExtResource("41")', escena)

    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_marcadores_mundo_957.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("37 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
