from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "godot" / "assets"
CARPETA = ASSETS / "cc0" / "quaternius_stylized_tree"
PROCEDENCIA = ASSETS / "procedencia.json"
ARTE = ROOT / "godot" / "arte" / "arboles_quaternius.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_arboles_cc0_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
GITATTRIBUTES = ROOT / ".gitattributes"

MODELOS = ("Tree_1", "Pine_2", "DeadTree_5")


class ArbolesCC0Test(unittest.TestCase):
    def test_incorpora_solo_tres_modelos_originales_con_mtl(self) -> None:
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
                ruta = f"cc0/quaternius_stylized_tree/{nombre}.{extension}"
                self.assertIn(ruta, fichas)
                self.assertEqual(fichas[ruta]["autor"], "Quaternius")
                self.assertEqual(fichas[ruta]["licencia"], "CC0-1.0")
                self.assertEqual(
                    fichas[ruta]["fuente"],
                    "https://quaternius.com/packs/stylizedtree.html",
                )
                self.assertEqual(len(fichas[ruta]["sha256"]), 64)

    def test_obj_es_texto_y_no_evita_la_regla_lfs_de_binarios(self) -> None:
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.obj    text", atributos)
        self.assertIn("*.glb   filter=lfs", atributos)
        self.assertIn("*.fbx   filter=lfs", atributos)

    def test_adapta_materiales_al_shader_comun_y_sin_sombras(self) -> None:
        codigo = ARTE.read_text(encoding="utf-8")
        self.assertIn("https://quaternius.com/packs/stylizedtree.html", codigo)
        self.assertIn("CC0-1.0", codigo)
        self.assertIn("License.txt", codigo)
        for nombre in MODELOS:
            self.assertIn(f'"{nombre}.obj"', codigo)
        self.assertIn("Espacio3D.SHADER_PSX", codigo)
        self.assertIn("set_surface_override_material", codigo)
        self.assertIn("SHADOW_CASTING_SETTING_OFF", codigo)
        self.assertIn("visibility_range_end", codigo)

    def test_arboles_quedan_detras_de_las_fachadas(self) -> None:
        # Las fachadas de la calle están a |x| ≈ 5,5 m: más cerca, la copa
        # atraviesa el muro (comprobado en captura).
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        posiciones = re.findall(r"_arbol\(mundo, \d+, [^,]+, Vector3\(([-\d.]+), 0\.0, ([-\d.]+)\)", codigo)
        self.assertEqual(len(posiciones), 6)
        for x, z in posiciones:
            self.assertTrue(abs(float(x)) >= 10.5 or abs(float(z)) >= 20.0, (x, z))

    def test_montaje_es_pequeno_determinista_y_solo_del_trayecto(self) -> None:
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn("INSTANCIAS_ARBOLES := 6", codigo)
        self.assertIn("DRAW_CALLS_BASE_MAX := 12", codigo)
        self.assertEqual(codigo.count("_arbol(mundo,"), 6)
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
        self.assertIn('[ext_resource type="Script" path="res://guion/dia_arboles_cc0_app.gd" id="23"]', escena)
        self.assertIn('[node name="ArbolesCC0Controller" type="Node" parent="."]\nscript = ExtResource("23")', escena)
        self.assertIn('script = ExtResource("1")', escena)


if __name__ == "__main__":
    unittest.main()
