from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
EXPORTAR = ROOT / "dist" / "exportar-godot-alpha.sh"
NOTAS = ROOT / "docs" / "alpha-playtest-2026-09-13.md"


class AlphaNotasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.exportar = EXPORTAR.read_text(encoding="utf-8")
        cls.notas = NOTAS.read_text(encoding="utf-8")

    def test_empaquetado_exige_notas_versionadas(self):
        self.assertIn('NOTAS_ALPHA="$RAIZ/docs/alpha-playtest-2026-09-13.md"', self.exportar)
        self.assertIn('if [ ! -f "$NOTAS_ALPHA" ]', self.exportar)

    def test_linux_y_windows_reciben_las_mismas_notas(self):
        self.assertIn(
            'cp "$NOTAS_ALPHA" "$SALIDA/godot-linux/NOTAS-ALPHA.md"',
            self.exportar,
        )
        self.assertIn(
            'cp "$NOTAS_ALPHA" "$SALIDA/godot-windows/NOTAS-ALPHA.md"',
            self.exportar,
        )

    def test_notas_identifican_baseline_y_gates_humanos(self):
        self.assertIn("alpha generada por #270", self.notas)
        self.assertIn("0216c7a5de49b24313f6d0c59dfbb1627744c057", self.notas)
        self.assertIn("## Gates humanos que esta alpha debe resolver", self.notas)
        self.assertIn("CI/Alpha automáticas", self.notas)
        self.assertIn("no equivalen", self.notas)


if __name__ == "__main__":
    unittest.main()
