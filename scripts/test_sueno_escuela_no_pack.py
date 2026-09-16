from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUTAS = [
    ROOT / "godot" / "guion" / "sueno_escuela.gd",
    ROOT / "godot" / "guion" / "sueno_escuela_3d.gd",
    ROOT / "godot" / "guion" / "sueno_escuela_audio.gd",
]


class SuenoEscuelaNoPackTest(unittest.TestCase):
    def test_runtime_no_referencia_styloo_ni_binarios_externos(self):
        texto = "\n".join(ruta.read_text(encoding="utf-8") for ruta in RUTAS)
        self.assertNotIn("styloo", texto.lower())
        self.assertNotIn("classroom-asset-pack", texto.lower())
        self.assertNotIn(".glb", texto.lower())
        self.assertNotIn(".fbx", texto.lower())


if __name__ == "__main__":
    unittest.main()
