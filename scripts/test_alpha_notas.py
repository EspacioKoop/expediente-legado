from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
EXPORTAR = ROOT / "dist" / "exportar-godot-alpha.sh"
NOTAS = ROOT / "docs" / "alpha-playtest-2026-09-15.md"


class AlphaNotasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.exportar = EXPORTAR.read_text(encoding="utf-8")
        cls.notas = NOTAS.read_text(encoding="utf-8")

    def test_empaquetado_exige_notas_versionadas(self):
        self.assertIn('NOTAS_ALPHA="$RAIZ/docs/alpha-playtest-2026-09-15.md"', self.exportar)
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

    def test_paquetes_incluyen_identificacion_de_build(self):
        self.assertIn('BUILD_SHA="${GITHUB_SHA:-', self.exportar)
        self.assertIn('BUILD_REF="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-local}}"', self.exportar)
        self.assertIn('BUILD-INFO.txt', self.exportar)
        self.assertIn('build_sha=$BUILD_SHA', self.exportar)
        self.assertIn('source_ref=$BUILD_REF', self.exportar)
        self.assertIn('notes=$NOTAS_NOMBRE', self.exportar)

    def test_notas_identifican_baseline_y_gates_humanos(self):
        self.assertIn("0b828dd7a3d0061801b90f8cf94119d8e5277580", self.notas)
        self.assertIn("## Gates humanos que esta alpha debe resolver", self.notas)
        self.assertIn("CI/Alpha automáticas", self.notas)
        self.assertIn("no equivalen", self.notas)
        self.assertIn("BUILD-INFO.txt", self.notas)

    def test_notas_separan_extras_del_recorrido_y_pr_abierta(self):
        self.assertIn("## Pruebas focales de las novedades", self.notas)
        self.assertIn("PR #503", self.notas)
        self.assertIn("no forma parte de esta alpha", self.notas)
        self.assertIn("runtime activo sigue siendo Peanut-GB", self.notas)


if __name__ == "__main__":
    unittest.main()
