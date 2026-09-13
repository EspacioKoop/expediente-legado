from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "godot" / "assets"
CARPETA = ASSETS / "cc0" / "quaternius_ultimate_nature"
PROCEDENCIA = ASSETS / "procedencia.json"
ARTE = ROOT / "godot" / "arte" / "naturaleza_quaternius.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_naturaleza_cc0_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
GITATTRIBUTES = ROOT / ".gitattributes"

MODELOS = ("Bush_1", "Bush_2", "Rock_1", "Rock_5")


class NaturalezaCC0Test(unittest.TestCase):
    def test_incorpora_solo_cuatro_modelos_originales_con_mtl(self) -> None:
        esperados = {f"{nombre}.{extension}" for nombre in MODELOS for extension in ("obj", "mtl")}
        presentes = {
            ruta.name
            for ruta in CARPETA.iterdir()
            if ruta.is_file() and ruta.suffix in {".obj", ".mtl"}
        }
        self.assertEqual(presentes, esperados)
        self.assertFalse(any(CARPETA.glob("*.glb")))
        self.assertFalse(any(CARPETA.glob("*.fbx")))
        self.assertFalse(any(CARPETA.glob("*.blend")))

    def test_todos_los_originales_tienen_procedencia_cc0_y_hash(self) -> None:
        datos = json.loads(PROCEDENCIA.read_text(encoding="utf-8"))
        fichas = {ficha["ruta"]: ficha for ficha in datos["assets"]}
        for nombre in MODELOS:
            for extension in ("obj", "mtl"):
                ruta = f"cc0/quaternius_ultimate_nature/{nombre}.{extension}"
                self.assertIn(ruta, fichas)
                self.assertEqual(fichas[ruta]["autor"], "Quaternius")
                self.assertEqual(fichas[ruta]["licencia"], "CC0-1.0")
                self.assertEqual(
                    fichas[ruta]["fuente"],
                    "https://quaternius.com/packs/ultimatenature.html",
                )
                self.assertEqual(len(fichas[ruta]["sha256"]), 64)

    def test_obj_es_texto_y_no_evita_la_regla_lfs_de_binarios(self) -> None:
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.obj    text", atributos)
        self.assertIn("*.glb   filter=lfs", atributos)
        self.assertIn("*.fbx   filter=lfs", atributos)

    def test_adapta_materiales_al_shader_comun_y_sin_sombras(self) -> None:
        codigo = ARTE.read_text(encoding="utf-8")
        self.assertIn("https://quaternius.com/packs/ultimatenature.html", codigo)
        self.assertIn("CC0-1.0", codigo)
        self.assertIn("ae16b37476c031075e4e767a848771b92ea5c4e0", codigo)
        for nombre in MODELOS:
            self.assertIn(f'"{nombre}.obj"', codigo)
        self.assertIn("Espacio3D.SHADER_PSX", codigo)
        self.assertIn("material_override", codigo)
        self.assertIn("SHADOW_CASTING_SETTING_OFF", codigo)
        self.assertIn("visibility_range_end", codigo)

    def test_montaje_es_pequeno_determinista_y_solo_del_trayecto(self) -> None:
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn("INSTANCIAS_NATURALEZA := 8", codigo)
        self.assertIn("DRAW_CALLS_BASE_MAX := 8", codigo)
        self.assertEqual(codigo.count("_pieza(mundo,"), 8)
        self.assertIn('!= "trayecto"', codigo)
        for aleatorio in ("randf(", "randi(", "randomize("):
            self.assertNotIn(aleatorio, codigo)

    def test_no_anade_fisica_interaccion_ni_gameplay(self) -> None:
        codigo = ARTE.read_text(encoding="utf-8") + CONTROLADOR.read_text(encoding="utf-8")
        for prohibido in (
            "StaticBody3D",
            "CollisionShape3D",
            "Area3D",
            "Interactuable3D",
            "CharacterBody3D",
            "InputEventKey",
            "Jornada.",
            "Partida",
        ):
            self.assertNotIn(prohibido, codigo)

    def test_dia_conserva_la_raiz_y_activa_el_controller_natural(self) -> None:
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_clima_app.gd"', escena)
        self.assertIn('path="res://guion/dia_naturaleza_cc0_app.gd"', escena)
        self.assertIn('[node name="NaturalezaCC0Controller" type="Node" parent="."]', escena)
        self.assertIn('script = ExtResource("1")', escena)


if __name__ == "__main__":
    unittest.main()
