import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CONTRATO = ROOT / "godot" / "guion" / "marcadores_mundo.gd"
VISUAL = ROOT / "godot" / "guion" / "marcador_mundo_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_marcadores_mundo_app.gd"
PANEL = ROOT / "godot" / "guion" / "marcadores_mundo_panel.gd"
TEXTOS = ROOT / "godot" / "datos" / "marcadores_mundo_textos.json"
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

    def test_controller_restaura_y_apunta_sin_controles_paralelos(self):
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        escena = ESCENA.read_text(encoding="utf-8")

        self.assertIn("class_name DiaMarcadoresMundoApp", codigo)
        self.assertIn("MarcadoresMundo.listar(_host.jornada, zona)", codigo)
        self.assertIn('String(_host.jornada.get("fase", ""))', codigo)
        self.assertIn('has_method("_guardar_o_avisar")', codigo)
        self.assertIn("not is_instance_valid(_host._mundo)", codigo)
        self.assertIn("mundo.remove_child(anterior)", codigo)

        self.assertIn('get_node_or_null("/root/MenuGlobal")', codigo)
        self.assertIn('_boton_menu.text = _cadena("menu")', codigo)
        self.assertIn("func _physics_process(_delta: float)", codigo)
        self.assertIn("project_ray_origin", codigo)
        self.assertIn("project_ray_normal", codigo)
        self.assertIn("PhysicsRayQueryParameters3D.create", codigo)
        self.assertIn("direct_space_state.intersect_ray", codigo)
        self.assertIn("mundo.to_local(posicion_global)", codigo)
        self.assertIn("static func marcador_cercano_a", codigo)
        self.assertIn("consulta.exclude = [caminante.get_rid()]", codigo)

        self.assertNotIn("InputMap.add_action", codigo)
        self.assertNotIn("KEY_M", codigo)
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

    def test_panel_es_minimo_acotado_y_usa_acciones_semanticas(self):
        codigo = PANEL.read_text(encoding="utf-8")

        self.assertIn("extends PanelContainer", codigo)
        self.assertIn("Node.PROCESS_MODE_ALWAYS", codigo)
        self.assertIn("OptionButton.new()", codigo)
        self.assertIn("LineEdit.new()", codigo)
        self.assertIn("_texto.max_length = MarcadoresMundo.MAX_TEXTO", codigo)
        self.assertIn('evento.is_action_pressed("cancelar")', codigo)
        self.assertIn("cantidad >= MarcadoresMundo.LIMITE_POR_ZONA", codigo)
        self.assertIn("signal eliminar_zona_solicitado", codigo)
        self.assertIn("ConfirmationDialog.new()", codigo)
        self.assertIn('_limpiar_zona.text = _cadena("limpiar_zona")', codigo)

        for tipo in (
            "TIPO_TIZA",
            "TIPO_CINTA",
            "TIPO_NOTA",
            "TIPO_CARBON",
            "TIPO_OBJETO",
        ):
            self.assertIn(f"MarcadoresMundo.{tipo}", codigo)
        for color in (
            "COLOR_BLANCO",
            "COLOR_AMARILLO",
            "COLOR_ROJO",
            "COLOR_AZUL",
            "COLOR_VERDE",
        ):
            self.assertIn(f"MarcadoresMundo.{color}", codigo)

        self.assertNotIn("Partida", codigo)
        self.assertNotIn("Economia", codigo)
        self.assertNotIn("InputMap.add_action", codigo)

    def test_copy_visible_vive_fuera_del_gdscript(self):
        import json

        datos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        self.assertEqual(datos["menu"], "Marcadores")
        self.assertEqual(datos["limpiar_zona"], "Limpiar zona")
        self.assertIn("texto_placeholder", datos)
        self.assertIn('RUTA_TEXTOS := "res://datos/marcadores_mundo_textos.json"', PANEL.read_text(encoding="utf-8"))
        self.assertIn('RUTA_TEXTOS := "res://datos/marcadores_mundo_textos.json"', CONTROLADOR.read_text(encoding="utf-8"))

    def test_borrado_apuntado_no_necesita_colision_en_la_marca(self):
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        visual = VISUAL.read_text(encoding="utf-8")

        self.assertIn("MarcadoresMundo.posicion_de(datos).distance_squared_to(punto)", codigo)
        self.assertIn("RADIO_BORRADO", codigo)
        self.assertIn("_marcador_apuntado_id", codigo)
        self.assertIn("func _confirmar_eliminacion_zona()", codigo)
        self.assertIn("eliminar_zona_actual() > 0", codigo)
        self.assertNotIn("CollisionShape3D", visual)
        self.assertNotIn("Area3D", visual)

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
