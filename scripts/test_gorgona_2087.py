from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GORGONA = ROOT / "godot/guion/juicio_combate_gorgona_3d.gd"


class Gorgona2087Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = GORGONA.read_text(encoding="utf-8")

    def test_reutiliza_controlador_sin_duplicar_politica(self):
        self.assertIn('preload("res://guion/juicio_combate_controlador_3d.gd")', self.codigo)
        self.assertIn("CONTROLADOR.geometria(unidad)", self.codigo)
        self.assertIn("ARQUETIPOS.MARCAR_ZONA", self.codigo)
        self.assertIn("ARQUETIPOS.ACTIVAR_ZONA", self.codigo)
        self.assertIn("ARQUETIPOS.RECUPERAR", self.codigo)
        codigo = "\n".join(
            linea for linea in self.codigo.splitlines()
            if not linea.lstrip().startswith("#")
        )
        for prohibido in (
            "ARQUETIPOS.avanzar(",
            "CONTROLADOR.avanzar(",
            "temporizador",
            "resultado_ataque_rival",
            "_aplicar_impacto_rival",
            "Partida.",
            "Jornada.",
            "petrific",
            "stun",
            "loot",
            "XP",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, codigo)

    def test_api_standalone_y_cono_legible(self):
        self.assertIn("static func montar(anfitrion: Node3D) -> Dictionary:", self.codigo)
        self.assertIn("static func pintar(", self.codigo)
        self.assertIn("static func limpiar(presentacion: Dictionary) -> void:", self.codigo)
        self.assertIn('cono.name = "ConoMirada"', self.codigo)
        self.assertIn("Mesh.PRIMITIVE_TRIANGLES", self.codigo)
        self.assertIn("CONTROLADOR.ZONA_LARGO", self.codigo)
        self.assertIn("CONTROLADOR.ZONA_ANCHO", self.codigo)
        self.assertIn('"estado_visual"] = "preparar"', self.codigo)
        self.assertIn('"estado_visual"] = "activa"', self.codigo)
        self.assertIn('"estado_visual"] = "recuperar"', self.codigo)

    def test_reduccion_movimiento_no_cambia_geometria_ni_timing(self):
        self.assertIn("reduccion_movimiento: bool", self.codigo)
        self.assertIn("var rumbo := float(geometria.get", self.codigo)
        self.assertIn("var origen: Vector3 = geometria.get", self.codigo)
        self.assertNotIn("Tween", self.codigo)
        self.assertNotIn("create_timer", self.codigo)
        self.assertNotIn("delta", self.codigo)


if __name__ == "__main__":
    unittest.main()
