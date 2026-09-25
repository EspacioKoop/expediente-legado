from pathlib import Path
import hashlib
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "godot" / "guion" / "oficina_fotorealista_98.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_oficina_utileria_app.gd"
ASSETS = ROOT / "godot" / "assets"
PROCEDENCIA = ASSETS / "procedencia.json"

ARCHIVOS = (
    "fax_98.webp",
    "fotocopiadora_98.webp",
    "dispensador_agua_98.webp",
    "grapadora_98.webp",
    "perforadora_98.webp",
)


class OficinaFotorealista98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.registro = json.loads(PROCEDENCIA.read_text(encoding="utf-8"))

    def test_monta_los_cinco_props_y_solo_en_archivo(self):
        for archivo in ARCHIVOS:
            self.assertIn(f'"{archivo}"', self.runtime)
        self.assertIn("OficinaFotorealista98.montar(mundo)", self.controlador)
        self.assertIn('String(dia.jornada.get("fase", "")) == "archivo"', self.controlador)

    def test_sprite3d_respeta_profundidad_luz_y_transparencia(self):
        for contrato in (
            "Sprite3D.new()",
            "BaseMaterial3D.BILLBOARD_FIXED_Y",
            "SpriteBase3D.ALPHA_CUT_DISCARD",
            "sprite.shaded = true",
            "GeometryInstance3D.SHADOW_CASTING_SETTING_OFF",
            "sprite.pixel_size",
        ):
            self.assertIn(contrato, self.runtime)
        self.assertNotIn("no_depth_test = true", self.runtime)
        self.assertNotIn("fixed_size = true", self.runtime)

    def test_es_dressing_sin_fisica_ni_interaccion(self):
        for termino in (
            "Area3D",
            "CollisionShape3D",
            "Interactuable3D",
            "Jornada.",
            "Partida",
            "guardar(",
        ):
            self.assertNotIn(termino, self.runtime)

    def test_lote_es_idempotente(self):
        self.assertIn("raiz.has_node(NOMBRE_CAPA)", self.runtime)
        self.assertIn('NOMBRE_CAPA := "OficinaFotorealista98"', self.runtime)

    def test_procedencia_y_sha_corresponden_a_los_binarios(self):
        por_ruta = {ficha["ruta"]: ficha for ficha in self.registro["assets"]}
        for archivo in ARCHIVOS:
            rel = f"texturas/oficina_ai_98/{archivo}"
            ruta = ASSETS / rel
            self.assertTrue(ruta.is_file(), rel)
            self.assertIn(rel, por_ruta)
            real = hashlib.sha256(ruta.read_bytes()).hexdigest()
            self.assertEqual(real, por_ruta[rel]["sha256"], rel)
            self.assertLess(ruta.stat().st_size, 10 * 1024, rel)


if __name__ == "__main__":
    unittest.main()
