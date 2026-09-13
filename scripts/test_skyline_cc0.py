from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOD = ROOT / "godot" / "arte" / "skyline_quaternius.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_skyline_cc0_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class SkylineCC0Test(unittest.TestCase):
    def test_fija_fuente_cc0_y_espejo_reproducible(self) -> None:
        codigo = LOD.read_text(encoding="utf-8")
        self.assertIn("https://quaternius.com/packs/ultimatetexturedbuildings.html", codigo)
        self.assertIn("CC0-1.0", codigo)
        self.assertIn("113de616a675a17fcad81bf61d9cbc62211408be", codigo)
        for modelo in (
            "3Story_Balcony_Mat.obj",
            "4Story_Mat.obj",
            "6Story_Stack_Mat.obj",
        ):
            self.assertIn(modelo, codigo)

    def test_el_lod_tiene_tres_perfiles_y_shader_comun(self) -> None:
        codigo = LOD.read_text(encoding="utf-8")
        self.assertIn("_tres_pisos_balcon", codigo)
        self.assertIn("_cuatro_pisos", codigo)
        self.assertIn("_seis_pisos_pila", codigo)
        self.assertIn("Espacio3D.SHADER_PSX", codigo)
        self.assertIn("BoxMesh.new()", codigo)

    def test_es_fondo_sin_colision_ni_interaccion(self) -> None:
        codigo = (LOD.read_text(encoding="utf-8") + CONTROLADOR.read_text(encoding="utf-8"))
        for prohibido in (
            "StaticBody3D",
            "CollisionShape3D",
            "Area3D",
            "Interactuable3D",
            "KEY_E",
            "InputEventKey",
        ):
            self.assertNotIn(prohibido, codigo)

    def test_solo_monta_en_trayecto_y_repite_los_tres_lod(self) -> None:
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn('!= "trayecto"', codigo)
        self.assertEqual(codigo.count("SkylineQuaternius.MODELO_BALCON"), 2)
        self.assertEqual(codigo.count("SkylineQuaternius.MODELO_CUATRO"), 2)
        self.assertEqual(codigo.count("SkylineQuaternius.MODELO_PILA"), 2)
        self.assertGreaterEqual(codigo.count("_edificio("), 7)

    def test_dia_conserva_raiz_historica_y_activa_skyline(self) -> None:
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_clima_app.gd"', escena)
        self.assertIn('path="res://guion/dia_skyline_cc0_app.gd"', escena)
        self.assertIn('[node name="SkylineCC0Controller" type="Node" parent="."]', escena)
        self.assertIn('script = ExtResource("1")', escena)


if __name__ == "__main__":
    unittest.main()
