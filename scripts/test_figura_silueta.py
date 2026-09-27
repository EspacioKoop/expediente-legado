from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest

from scripts.godot_pruebas import PROYECTO, importar_proyecto, motor


ROOT = Path(__file__).resolve().parents[1]
FIGURA = ROOT / "godot" / "guion" / "figura_silueta.gd"
IDLE = ROOT / "godot" / "guion" / "figura_idle_3d.gd"
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"
SUENO = ROOT / "godot" / "guion" / "sueno.gd"


class FiguraSiluetaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = FIGURA.read_text(encoding="utf-8")
        cls.codigo_ejecutable = "\n".join(
            linea for linea in cls.codigo.splitlines() if not linea.lstrip().startswith("#")
        )
        cls.idle = IDLE.read_text(encoding="utf-8")
        cls.espacio = ESPACIO.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")

    def test_no_regresa_a_cajas_prismaticas(self):
        self.assertNotIn("BoxMesh", self.codigo_ejecutable)
        self.assertIn("CapsuleMesh", self.codigo_ejecutable)
        self.assertIn("SphereMesh", self.codigo_ejecutable)

    def test_conserva_abstraccion_y_altura_compartida(self):
        self.assertIn("const ALTO := 1.94", self.codigo)
        self.assertIn("return ALTO", self.codigo)
        self.assertNotIn("modelo", self.codigo_ejecutable.lower())
        self.assertNotIn("retrato", self.codigo_ejecutable.lower())

    def test_sueno_activa_microgestos_sin_navegacion(self):
        self.assertIn('"movimiento_idle": true', self.sueno)
        self.assertIn('"mirar_jugador": quien.get("acusado", false)', self.sueno)
        self.assertIn('figura.get("movimiento_idle", false)', self.espacio)
        self.assertIn("FiguraIdle3D.new()", self.espacio)
        self.assertIn("AMPLITUD_RESPIRACION", self.idle)
        self.assertIn("DISTANCIA_ATENCION", self.idle)
        self.assertIn('get_camera_3d()', self.idle)
        self.assertNotIn("NavigationAgent3D", self.idle)
        self.assertNotIn("Partida", self.idle)

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
                assert(figura.get_node_or_null("Cabeza") is MeshInstance3D)
                assert(figura.get_node_or_null("BrazoIzquierdo") is MeshInstance3D)
                assert(figura.get_node_or_null("BrazoDerecho") is MeshInstance3D)

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

                var cabeza := figura.get_node("Cabeza") as Node3D
                var escala_inicial := figura.scale
                var rotacion_inicial := cabeza.rotation
                var idle := FiguraIdle3D.new()
                figura.add_child(idle)
                idle.configurar(figura, 0.7, false)
                idle.reduccion_movimiento = false
                idle._process(0.75)
                assert(not is_equal_approx(figura.scale.y, escala_inicial.y))
                assert(not is_equal_approx(cabeza.rotation.y, rotacion_inicial.y))

                idle.reduccion_movimiento = true
                idle._process(0.1)
                assert(figura.scale.is_equal_approx(escala_inicial))
                assert(cabeza.rotation.is_equal_approx(rotacion_inicial))

                var mundo := Node3D.new()
                get_root().add_child(mundo)
                Espacio3D.construir(
                    mundo,
                    {
                        "suelo": Vector2(8, 8),
                        "figuras":
                        [
                            {
                                "pos": Vector3.ZERO,
                                "movimiento_idle": true,
                                "fase_idle": 0.5,
                                "mirar_jugador": true,
                            }
                        ],
                    }
                )
                var controladores := mundo.find_children("IdleFigura", "", true, false)
                assert(controladores.size() == 1)
                assert(controladores[0] is FiguraIdle3D)

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
