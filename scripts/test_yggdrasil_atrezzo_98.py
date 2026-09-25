from pathlib import Path
import hashlib
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "godot" / "guion" / "yggdrasil_atrezzo_98.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_yggdrasil_app.gd"
BIT98 = ROOT / "godot" / "guion" / "bit98_dressing.gd"
TIENDA = ROOT / "godot" / "guion" / "tienda_videojuegos.gd"
ROMS = ROOT / "godot" / "datos" / "roms_propias.json"
ASSETS = ROOT / "godot" / "assets"
PROCEDENCIA = ASSETS / "procedencia.json"
GITATTRIBUTES = ROOT / ".gitattributes"

ARCHIVOS = (
    "bonsai_yggdrasil_98.webp",
    "yggdrasils_egg_atrezzo_98.webp",
)


class YggdrasilAtrezzo98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.bit98 = BIT98.read_text(encoding="utf-8")
        cls.tienda = TIENDA.read_text(encoding="utf-8")
        cls.roms = ROMS.read_text(encoding="utf-8")
        cls.registro = json.loads(PROCEDENCIA.read_text(encoding="utf-8"))
        cls.gitattributes = GITATTRIBUTES.read_text(encoding="utf-8")

    def test_bonsai_se_monta_solo_como_dressing_en_casa(self):
        self.assertIn("YggdrasilAtrezzo98.montar_casa(mundo)", self.controlador)
        for contrato in (
            "class_name YggdrasilAtrezzo98",
            "Sprite3D.new()",
            "BaseMaterial3D.BILLBOARD_FIXED_Y",
            "SpriteBase3D.ALPHA_CUT_DISCARD",
        ):
            self.assertIn(contrato, self.runtime)
        for termino in (
            "CollisionShape3D",
            "Interactuable3D",
            "registrar_semilla",
            "Jornada.",
            "Partida",
        ):
            self.assertNotIn(termino, self.runtime)

    def test_yggdrasils_egg_es_solo_atrezzo_de_bit98(self):
        self.assertIn("yggdrasils_egg_atrezzo_98.webp", self.bit98)
        self.assertIn('"YggdrasilsEggAtrezzo98"', self.bit98)
        self.assertNotIn("yggdrasils_egg_atrezzo_98.webp", self.tienda)
        self.assertNotIn("yggdrasils_egg_atrezzo_98.webp", self.roms)

    def test_procedencia_y_sha_corresponden_a_los_binarios(self):
        por_ruta = {ficha["ruta"]: ficha for ficha in self.registro["assets"]}
        for archivo in ARCHIVOS:
            rel = f"texturas/yggdrasil_ai_98/{archivo}"
            ruta = ASSETS / rel
            self.assertTrue(ruta.is_file(), rel)
            self.assertIn(rel, por_ruta)
            real = hashlib.sha256(ruta.read_bytes()).hexdigest()
            self.assertEqual(real, por_ruta[rel]["sha256"], rel)
            self.assertLess(ruta.stat().st_size, 10 * 1024, rel)

    def test_webp_pequenos_no_dependen_de_lfs(self):
        self.assertIn(
            "godot/assets/texturas/yggdrasil_ai_98/*.webp -filter -diff -merge -text",
            self.gitattributes,
        )


if __name__ == "__main__":
    unittest.main()
