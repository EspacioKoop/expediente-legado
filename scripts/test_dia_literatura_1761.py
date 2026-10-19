"""Regresión estructural del adaptador opt-in de literatura (#1761).

La suite de Godot/CI comprueba parsing y ejecución; esta regresión evita
reintroducir la dependencia del autoload en el orquestador DiaApp.
"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
HELPER = (ROOT / "godot/guion/dia_literatura_app.gd").read_text(encoding="utf-8")


def cuerpo(nombre):
    match = re.search(r"(?ms)^func " + re.escape(nombre) + r"\([^)]*\) -> [^\n]*:\n(.*?)(?=^func |\Z)", DIA)
    if not match:
        raise AssertionError(f"Falta el hook {nombre}")
    return match.group(1)


class DiaLiteratura1761Test(unittest.TestCase):
    def test_orquestador_delega_sin_consultar_autoload(self):
        self.assertIn('const DIA_LITERATURA_APP = preload("res://guion/dia_literatura_app.gd")', DIA)
        vincular = cuerpo("_vincular_literatura_partida")
        registro = cuerpo("_registro_literario_para_sueno")
        self.assertIn("DIA_LITERATURA_APP.vincular_partida(self, partida.estado)", vincular)
        self.assertIn("return DIA_LITERATURA_APP.registro_para_sueno(self)", registro)
        self.assertNotIn('get_node_or_null("/root/GestorLiteratura")', DIA)
        self.assertIn("_vincular_literatura_partida()", DIA)
        self.assertIn("_registro_literario_para_sueno()", DIA)

    def test_helper_conserva_fallback_en_gates_sin_arbol(self):
        self.assertIn("static func vincular_partida(host: Node, estado: Dictionary) -> void:", HELPER)
        self.assertIn("static func registro_para_sueno(host: Node) -> Dictionary:", HELPER)
        self.assertEqual(HELPER.count("if not host.is_inside_tree():"), 2)
        self.assertIn('gestor.has_method("vincular_a_estado")', HELPER)
        self.assertIn('gestor.has_method("obtener_registro_literario")', HELPER)
        self.assertIn("return registro if typeof(registro) == TYPE_DICTIONARY else {}", HELPER)

    def test_helper_sin_segunda_autoridad_de_partida(self):
        self.assertNotIn("Partida.new()", HELPER)
        self.assertNotIn("Jornada.nueva(", HELPER)
        self.assertLess(len(DIA.splitlines()), 800)


if __name__ == "__main__":
    unittest.main()
