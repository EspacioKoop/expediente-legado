from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "godot" / "escenas" / "suenos" / "props_284" / "escuela_runtime.md"


class SuenoEscuelaRuntimeDocTest(unittest.TestCase):
    def test_documenta_ausencia_de_dependencia_externa_y_fisica_duplicada(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("no usa el School Classrooms Asset Pack", texto)
        self.assertIn("no crea `StaticBody3D` ni `CollisionShape3D`", texto)
        self.assertIn("frase ya conocida", texto)


if __name__ == "__main__":
    unittest.main()
