"""Segundo corte de #218: geometría real del Ultimate Buildings Pack CC0."""
from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "godot" / "assets"
CARPETA = ASSETS / "cc0" / "quaternius_ultimate_buildings"
PROCEDENCIA = ASSETS / "procedencia.json"
ARTE = ROOT / "godot" / "arte" / "edificios_cc0.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_edificios_cc0_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
GITATTRIBUTES = ROOT / ".gitattributes"
FUENTE = "https://quaternius.com/packs/ultimatetexturedbuildings.html"

MODELOS = ("2Story_Mat", "6Story_Stack_Mat", "4Story_Mat", "1Story_Sign_Mat")


class EdificiosCC0Test(unittest.TestCase):
    def test_incorpora_solo_cuatro_modelos_con_mtl(self) -> None:
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
                ruta = f"cc0/quaternius_ultimate_buildings/{nombre}.{extension}"
                self.assertIn(ruta, fichas)
                self.assertEqual(fichas[ruta]["autor"], "Quaternius")
                self.assertEqual(fichas[ruta]["licencia"], "CC0-1.0")
                self.assertEqual(fichas[ruta]["fuente"], FUENTE)
                self.assertEqual(len(fichas[ruta]["sha256"]), 64)

    def test_obj_es_texto_y_no_evita_la_regla_lfs_de_binarios(self) -> None:
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.obj    text", atributos)
        self.assertIn("*.fbx   filter=lfs", atributos)
        self.assertIn("*.blend filter=lfs", atributos)

    def test_cubre_los_cuatro_roles_del_contrato_218(self) -> None:
        contrato = (ROOT / "docs" / "assets" / "quaternius-ultimate-buildings.md").read_text(
            encoding="utf-8"
        )
        codigo = ARTE.read_text(encoding="utf-8")
        self.assertIn(FUENTE, codigo)
        self.assertIn("CC0-1.0", codigo)
        for rol, modelo in (
            ("RESIDENCIAL_MEDIO", "2Story_Mat.obj"),
            ("RESIDENCIAL_ALTO", "6Story_Stack_Mat.obj"),
            ("TERCIARIO", "4Story_Mat.obj"),
            ("COMERCIAL", "1Story_Sign_Mat.obj"),
        ):
            self.assertIn(f'const {rol} := "{modelo}"', codigo)
        for rol in (
            "bloque residencial bajo/medio",
            "bloque residencial alto",
            "edificio terciario/oficinas",
            "pieza comercial o de esquina",
        ):
            self.assertIn(rol, contrato)

    def test_altura_de_las_piezas_convertidas_queda_en_metros(self) -> None:
        # 4Story_Mat/6Story_Stack_Mat se exportaron con assimp desde FBX, que
        # exporta en centímetros; sin la corrección x0.01 medirían ~100 veces
        # más que 2Story_Mat/1Story_Sign_Mat (el pack original, en metros).
        alturas = {}
        for nombre in MODELOS:
            y_min, y_max = None, None
            for linea in (CARPETA / f"{nombre}.obj").read_text(encoding="utf-8").splitlines():
                if linea.startswith("v "):
                    y = float(linea.split()[2])
                    y_min = y if y_min is None else min(y_min, y)
                    y_max = y if y_max is None else max(y_max, y)
            alturas[nombre] = y_max - y_min
        self.assertLess(alturas["2Story_Mat"], 4.0)
        self.assertLess(alturas["1Story_Sign_Mat"], 3.0)
        self.assertLess(alturas["4Story_Mat"], 8.0)
        self.assertLess(alturas["6Story_Stack_Mat"], 10.0)
        self.assertGreater(alturas["6Story_Stack_Mat"], alturas["4Story_Mat"])
        self.assertGreater(alturas["4Story_Mat"], alturas["2Story_Mat"])

    def test_adapta_materiales_al_shader_comun_y_sin_sombras(self) -> None:
        codigo = ARTE.read_text(encoding="utf-8")
        self.assertIn("Espacio3D.SHADER_PSX", codigo)
        self.assertIn("material_override", codigo)
        self.assertIn("SHADOW_CASTING_SETTING_OFF", codigo)
        self.assertIn("visibility_range_end", codigo)

    def test_montaje_es_pequeno_determinista_y_solo_del_trayecto(self) -> None:
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        self.assertEqual(codigo.count("_edificio(\n\t\tmundo,"), 4)
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

    def test_dia_activa_el_controller_de_edificios_reales(self) -> None:
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_edificios_cc0_app.gd"', escena)
        self.assertIn('[node name="EdificiosCC0Controller" type="Node" parent="."]', escena)


if __name__ == "__main__":
    unittest.main()
