from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest

from scripts.godot_pruebas import PROYECTO, importar_proyecto, motor


ROOT = Path(__file__).resolve().parents[1]
FIGURA = ROOT / "godot" / "guion" / "figura_silueta.gd"


class FiguraSiluetaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = FIGURA.read_text(encoding="utf-8")
        cls.codigo_ejecutable = "\n".join(
            linea for linea in cls.codigo.splitlines() if not linea.lstrip().startswith("#")
        )

    def test_no_regresa_a_cajas_prismaticas(self):
        self.assertNotIn("BoxMesh", self.codigo_ejecutable)
        self.assertIn("CapsuleMesh", self.codigo_ejecutable)
        self.assertIn("SphereMesh", self.codigo_ejecutable)

    def test_conserva_abstraccion_y_altura_compartida(self):
        self.assertIn("const ALTO := 1.94", self.codigo)
        self.assertIn("return ALTO", self.codigo)
        self.assertNotIn("modelo", self.codigo_ejecutable.lower())
        self.assertNotIn("retrato", self.codigo_ejecutable.lower())

    def test_contrato_ejecutable_en_godot(self):
        importar_proyecto()
        guion = textwrap.dedent(
            """
            extends SceneTree

            func _init() -> void:
                var raiz := Node3D.new()
                get_root().add_child(raiz)
                var figura := FiguraSilueta.construir(raiz, Vector3.ZERO, Color.WHITE)
                assert(is_equal_approx(FiguraSilueta.altura(), 1.94))
                assert(figura.get_child_count() == 6)

                var cajas := 0
                var capsulas := 0
                var esferas := 0
                for hijo in figura.get_children():
                    assert(hijo is MeshInstance3D)
                    var malla := (hijo as MeshInstance3D).mesh
                    if malla is BoxMesh:
                        cajas += 1
                    elif malla is CapsuleMesh:
                        capsulas += 1
                    elif malla is SphereMesh:
                        esferas += 1

                assert(cajas == 0)
                assert(capsulas == 5)
                assert(esferas == 1)
                print("FIGURA_SILUETA_279_OK")
                quit(0)
            """
        )
        with tempfile.TemporaryDirectory() as temporal:
            ruta = Path(temporal) / "probar_figura_silueta_279.gd"
            ruta.write_text(guion, encoding="utf-8")
            resultado = subprocess.run(
                [
                    motor(),
                    "--headless",
                    "--path",
                    str(PROYECTO),
                    "--script",
                    str(ruta),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=30,
                check=False,
            )

        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("FIGURA_SILUETA_279_OK", resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
