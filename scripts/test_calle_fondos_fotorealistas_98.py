from pathlib import Path
import hashlib
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "godot" / "guion" / "calle_fondos_fotorealistas_98.gd"
SKYLINE = ROOT / "godot" / "guion" / "dia_skyline_cc0_app.gd"
ASSETS = ROOT / "godot" / "assets"
PROCEDENCIA = ASSETS / "procedencia.json"

ARCHIVOS = (
    "bloque_01.webp",
    "bloque_02.webp",
    "bloque_03.webp",
    "bloque_04.webp",
)


class CalleFondosFotorealistas98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.skyline = SKYLINE.read_text(encoding="utf-8")
        cls.registro = json.loads(PROCEDENCIA.read_text(encoding="utf-8"))

    def test_monta_cuatro_bloques_en_el_skyline_del_trayecto(self):
        for archivo in ARCHIVOS:
            self.assertIn(f'"{archivo}"', self.runtime)
        self.assertIn("CalleFondosFotorealistas98.montar(mundo)", self.skyline)
        self.assertIn("Vector3(-10.5, 0.0, -3.8)", self.runtime)
        self.assertIn("Vector3(10.7, 0.0, -2.2)", self.runtime)

    def test_son_impostores_3d_con_profundidad_y_sin_billboard(self):
        for contrato in (
            "Sprite3D.new()",
            "SpriteBase3D.ALPHA_CUT_DISCARD",
            "sprite.shaded = true",
            "sprite.double_sided = false",
            "sprite.fixed_size = false",
            "sprite.no_depth_test = false",
            "sprite.rotation_degrees.y",
            "sprite.pixel_size",
        ):
            self.assertIn(contrato, self.runtime)
        self.assertNotIn("BILLBOARD_", self.runtime)

    def test_no_introduce_fisica_interaccion_ni_reglas(self):
        for termino in (
            "Area3D",
            "CollisionShape3D",
            "Interactuable3D",
            "Jornada.",
            "Partida",
            "guardar(",
        ):
            self.assertNotIn(termino, self.runtime)

    def test_capa_es_idempotente(self):
        self.assertIn("mundo.has_node(NOMBRE_CAPA)", self.runtime)
        self.assertIn('NOMBRE_CAPA := "FondosFotorealistas98"', self.runtime)

    def test_assets_tienen_procedencia_sha_y_tamano_acotado(self):
        por_ruta = {ficha["ruta"]: ficha for ficha in self.registro["assets"]}
        for archivo in ARCHIVOS:
            rel = f"texturas/calle_ai_98/{archivo}"
            ruta = ASSETS / rel
            self.assertTrue(ruta.is_file(), rel)
            self.assertIn(rel, por_ruta)
            real = hashlib.sha256(ruta.read_bytes()).hexdigest()
            self.assertEqual(real, por_ruta[rel]["sha256"], rel)
            self.assertLess(ruta.stat().st_size, 10 * 1024, rel)


if __name__ == "__main__":
    unittest.main()
