import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "interaccion_combate_ambiental.gd"
RUNTIME = ROOT / "godot" / "guion" / "juicio_combate_ambiental_1772.gd"
RUNTIME_VOLCAR = ROOT / "godot" / "guion" / "juicio_combate_ambiental_volcar_1772.gd"
RUNTIME_EMPUJAR = ROOT / "godot" / "guion" / "juicio_combate_ambiental_empujar_1772.gd"
COMBATE = ROOT / "godot" / "guion" / "juicio_combate_3d.gd"
CONTEXTUAL = ROOT / "godot" / "guion" / "dia_combate_contextual_app.gd"
PRUEBA = "res://pruebas/pruebas_interaccion_combate_ambiental_1772.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class InteraccionCombateAmbiental1772Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = MODELO.read_text(encoding="utf-8")
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.runtime_volcar = RUNTIME_VOLCAR.read_text(encoding="utf-8")
        cls.runtime_empujar = RUNTIME_EMPUJAR.read_text(encoding="utf-8")
        cls.combate = COMBATE.read_text(encoding="utf-8")
        cls.contextual = CONTEXTUAL.read_text(encoding="utf-8")

    def test_tres_verbos_son_explicitos(self):
        for verbo in ("empujar", "volcar", "activar"):
            self.assertIn(f'"{verbo}"', self.fuente)
        self.assertIn('"verbos_combate"', self.fuente)
        self.assertIn("combate_permitido", self.fuente)

    def test_no_detecta_props_por_nombre_ni_toca_interaccion_normal(self):
        self.assertNotIn("find_child", self.fuente)
        self.assertNotIn("find_children", self.fuente)
        self.assertNotIn("get_node", self.fuente)
        self.assertNotIn("Interactuable3D", self.fuente)
        self.assertNotIn("nombre_objeto", self.fuente)

    def test_no_crea_consecuencias_o_progreso_paralelos(self):
        for simbolo in (
            "Partida.",
            "Jornada.",
            "SuenoCombate.",
            "Inventario.",
            "dinero",
            "pista",
            "veredicto",
            "experiencia",
            "recompensa",
            "loot",
            "dano",
        ):
            self.assertNotIn(simbolo, self.fuente.lower() if simbolo.islower() else self.fuente)

    def test_efectos_estan_acotados(self):
        self.assertIn("DESPLAZAMIENTO_EMPUJAR_MAX := 2.0", self.fuente)
        self.assertIn("OBSTACULO_VOLCAR_MAX := 4.0", self.fuente)
        self.assertIn('"interrumpe": true', self.fuente)
        self.assertIn('"solido_temporal": true', self.fuente)
        self.assertIn('"efecto_id": efecto_id', self.fuente)

    def test_primer_consumidor_runtime_es_activar_y_falla_cerrado(self):
        self.assertIn("class_name JuicioCombateAmbiental1772", self.runtime)
        self.assertIn("[InteraccionCombateAmbiental.ACTIVAR]", self.runtime)
        self.assertNotIn("InteraccionCombateAmbiental.EMPUJAR", self.runtime)
        self.assertNotIn("InteraccionCombateAmbiental.VOLCAR", self.runtime)
        self.assertIn("RADIO_USO := 1.8", self.runtime)
        self.assertIn('"fuera_de_alcance"', self.runtime)
        self.assertIn("OmniLight3D.new()", self.runtime)
        self.assertNotIn("Partida.", self.runtime)
        self.assertNotIn("Jornada.", self.runtime)

    def test_volcar_materializa_obstaculo_temporal_sin_tocar_host(self):
        self.assertIn("class_name JuicioCombateAmbientalVolcar1772", self.runtime_volcar)
        self.assertIn("InteraccionCombateAmbiental.VOLCAR", self.runtime_volcar)
        self.assertNotIn("InteraccionCombateAmbiental.EMPUJAR", self.runtime_volcar)
        self.assertNotIn("InteraccionCombateAmbiental.ACTIVAR", self.runtime_volcar)
        self.assertIn("StaticBody3D.new()", self.runtime_volcar)
        self.assertIn("CollisionShape3D.new()", self.runtime_volcar)
        self.assertIn("BoxShape3D.new()", self.runtime_volcar)
        self.assertIn("collision_layer = CAPA_OBSTACULO", self.runtime_volcar)
        self.assertIn("collision_layer = 0", self.runtime_volcar)
        self.assertNotIn("JuicioCombate3D", self.runtime_volcar)
        for simbolo in ("Partida.", "Jornada.", "Inventario.", "SuenoCombate"):
            self.assertNotIn(simbolo, self.runtime_volcar)

    def test_empujar_limita_usos_y_recarga_sin_tocar_host(self):
        self.assertIn("class_name JuicioCombateAmbientalEmpujar1772", self.runtime_empujar)
        self.assertIn("InteraccionCombateAmbiental.EMPUJAR", self.runtime_empujar)
        self.assertNotIn("InteraccionCombateAmbiental.VOLCAR", self.runtime_empujar)
        self.assertNotIn("InteraccionCombateAmbiental.ACTIVAR", self.runtime_empujar)
        self.assertIn("AnimatableBody3D.new()", self.runtime_empujar)
        self.assertIn("prop.sync_to_physics = false", self.runtime_empujar)
        self.assertIn("CollisionShape3D.new()", self.runtime_empujar)
        self.assertIn("BoxShape3D.new()", self.runtime_empujar)
        self.assertIn("const USOS_MAX := 2", self.runtime_empujar)
        self.assertIn("const RECARGA_SEGUNDOS := 0.8", self.runtime_empujar)
        self.assertIn('"sin_usos"', self.runtime_empujar)
        self.assertIn('"en_recarga"', self.runtime_empujar)
        self.assertNotIn("JuicioCombate3D", self.runtime_empujar)
        for simbolo in ("Partida.", "Jornada.", "Inventario.", "SuenoCombate"):
            self.assertNotIn(simbolo, self.runtime_empujar)

    def test_host_contextual_habilita_prop_sin_pisar_ataques(self):
        self.assertIn("_combate.interaccion_ambiental_habilitada = true", self.contextual)
        self.assertIn('Input.is_action_just_pressed("inventario")', self.combate)
        self.assertIn('Input.is_action_just_pressed("interactuar")', self.combate)
        self.assertIn('Input.is_action_just_pressed("saltar")', self.combate)
        self.assertIn('Input.is_action_just_pressed("agacharse")', self.combate)
        for hardcode in ("KEY_I", "JOY_BUTTON_Y", "InputEventKey", "InputEventJoypadButton"):
            self.assertNotIn(hardcode, self.runtime + self.combate)

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
