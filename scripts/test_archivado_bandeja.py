from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "archivado_bandeja.gd"


class ArchivadoBandejaTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_estado_y_superficie_son_puros(self):
        self.assertIn("class_name ArchivadoBandeja", self.source)
        self.assertIn("extends RefCounted", self.source)
        for funcion in ("nueva", "colocar", "cerrar", "abandonar"):
            self.assertIn(f"static func {funcion}", self.source)
        self.assertNotIn("extends Node", self.source)
        self.assertNotIn("Partida", self.source)

    def test_reutiliza_la_regla_de_archivado(self):
        self.assertIn("Archivado.es_clasificable", self.source)
        self.assertIn("Archivado.evaluar", self.source)

    def test_error_no_elimina_la_carpeta(self):
        self.assertIn("Una colocación incorrecta no destruye el caso", self.source)
        self.assertIn('"pendientes": casos.duplicate(true)', self.source)
        self.assertIn('estado["colocaciones"].append', self.source)

    def test_abandono_es_valido_y_no_cierra_la_bandeja(self):
        self.assertIn('estado["abandonada"] = true', self.source)
        self.assertIn('Archivado.evaluar(estado.get("colocaciones", []))', self.source)
        self.assertIn('estado["cerrada"] = true', self.source)


if __name__ == "__main__":
    unittest.main()
