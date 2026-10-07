from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
EXPORTAR = ROOT / "dist" / "exportar-godot-alpha.sh"
NOTAS = ROOT / "docs" / "alpha-playtest-2026-10-07.md"


class AlphaNotasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.exportar = EXPORTAR.read_text(encoding="utf-8")
        cls.notas = NOTAS.read_text(encoding="utf-8")

    def test_empaquetado_exige_notas_versionadas(self):
        self.assertIn('NOTAS_ALPHA="$RAIZ/docs/alpha-playtest-2026-10-07.md"', self.exportar)
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

    def test_notas_identifican_baseline_y_no_validan_gates(self):
        # El guion del pase end-to-end (#9) fija el build exacto y deja claro que
        # una casilla marcada es una observación humana, no un gate cerrado.
        self.assertIn("35a2f362bc62c3b61194081baf661f3a43714bcf", self.notas)
        self.assertIn("BUILD-INFO.txt", self.notas)
        self.assertIn("no cierra por sí solo ningún gate", self.notas)

    def test_notas_guian_el_recorrido_canonico(self):
        self.assertIn("## Recorrido canónico (#9)", self.notas)
        self.assertIn("## Controles", self.notas)
        self.assertIn("## Cómo anotar", self.notas)
        self.assertIn("F9", self.notas)


if __name__ == "__main__":
    unittest.main()
