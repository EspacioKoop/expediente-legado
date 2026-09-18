from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "bolos_pasillo_3d.gd"
SCENE = ROOT / "godot" / "escenas" / "bolos_pasillo.tscn"
GODOT_TEST = ROOT / "godot" / "pruebas" / "pruebas_bolos_pasillo_3d.gd"


class BolosPasillo3DTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")
        self.scene = SCENE.read_text(encoding="utf-8")
        self.godot_test = GODOT_TEST.read_text(encoding="utf-8")

    def test_vertical_consumidor_del_nucleo_sin_partida(self):
        self.assertIn("class_name BolosPasillo3D", self.source)
        self.assertIn("extends Node3D", self.source)
        self.assertIn("Bolos.nueva(LANZADORES)", self.source)
        self.assertIn("Bolos.derribar(estado, nuevos)", self.source)
        self.assertNotIn("Partida", self.source)
        self.assertNotIn("RigidBody3D.new(", self.source)
        self.assertNotIn("extends RigidBody3D", self.source)

    def test_pista_tiene_diez_bolos_y_simulacion_acotada(self):
        bloque = re.search(
            r"const POSICIONES_BOLOS := \[(.*?)\n\]",
            self.source,
            flags=re.DOTALL,
        )
        self.assertIsNotNone(bloque)
        self.assertEqual(10, bloque.group(1).count("Vector3("))
        self.assertIn("const PASO_FIJO := 1.0 / 120.0", self.source)
        self.assertIn("const TIEMPO_MAXIMO_TIRO := 4.0", self.source)
        self.assertIn("simular_hasta_reposo", self.source)

    def test_entrada_es_semantica_y_valida_para_mando(self):
        self.assertIn(
            'Input.get_axis("mover_izquierda", "mover_derecha")',
            self.source,
        )
        self.assertIn('Input.is_action_just_pressed("interactuar")', self.source)
        self.assertIn('Input.is_action_just_pressed("cancelar")', self.source)
        self.assertIn("PreferenciasSiga.aplicar(PreferenciasSiga.cargar())", self.source)
        self.assertNotRegex(self.source, r"KEY_[A-Z0-9_]+")

    def test_escena_y_regresion_ejecutable_quedan_versionadas(self):
        self.assertIn('path="res://guion/bolos_pasillo_3d.gd"', self.scene)
        self.assertIn('load("res://escenas/bolos_pasillo.tscn")', self.godot_test)
        self.assertIn("simular_hasta_reposo()", self.godot_test)
        self.assertIn("fallar no bloquea el turno", self.godot_test)
        self.assertIn("abandonar devuelve resultado válido", self.godot_test)

    def test_regresion_queda_en_verificador_canonico(self):
        verificador = (ROOT / "scripts" / "verificar_godot.py").read_text(encoding="utf-8")
        self.assertIn('"bolos-pasillo"', verificador)
        self.assertIn(
            '["--script", "pruebas/pruebas_bolos_pasillo_3d.gd"]',
            verificador,
        )


if __name__ == "__main__":
    unittest.main()
