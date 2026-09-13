from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DRESSING = ROOT / "godot" / "guion" / "dia_dressing_cc0_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
PROCEDENCIA = ROOT / "godot" / "assets" / "procedencia.json"


class DressingCC0Test(unittest.TestCase):
    def test_la_escena_conserva_la_raiz_y_activa_el_controller(self) -> None:
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_clima_app.gd"', escena)
        self.assertIn('path="res://guion/dia_dressing_cc0_app.gd"', escena)
        self.assertIn('[node name="DressingCC0Controller" type="Node" parent="."]', escena)

    def test_controller_cubre_tres_espacios_sin_reemplazar_el_dia(self) -> None:
        codigo = DRESSING.read_text(encoding="utf-8")
        self.assertIn("extends Node", codigo)
        self.assertNotIn('extends "res://guion/dia_clima_app.gd"', codigo)
        self.assertIn("get_parent()", codigo)
        for fase in ('"archivo"', '"trayecto"', '"casa"'):
            self.assertIn(fase, codigo)

    def test_los_modelos_usados_tienen_procedencia(self) -> None:
        codigo = DRESSING.read_text(encoding="utf-8")
        datos = json.loads(PROCEDENCIA.read_text(encoding="utf-8"))
        rutas = {item["ruta"] for item in datos["assets"]}
        for modelo in (
            "computerScreen",
            "trashcan",
            "cardboardBoxClosed",
            "bookcaseClosed",
            "chairDesk",
        ):
            self.assertIn(f'"{modelo}"', codigo)
            self.assertTrue(
                any(ruta.startswith(f"modelos/{modelo}.") for ruta in rutas),
                f"{modelo} no está registrado en procedencia.json",
            )

    def test_interaccion_es_semantica(self) -> None:
        codigo = DRESSING.read_text(encoding="utf-8")
        self.assertIn("Interactuable3D.Verbo.EXAMINAR", codigo)
        self.assertNotIn("KEY_E", codigo)
        self.assertNotIn("is_key_pressed", codigo)
        self.assertNotIn("InputEventKey", codigo)

    def test_calle_combina_asfalto_y_revoco_cc0(self) -> None:
        calle = CALLE.read_text(encoding="utf-8")
        self.assertIn('"textura": "asfalto"', calle)
        self.assertGreaterEqual(calle.count('"textura": "gotele"'), 5)

        datos = json.loads(PROCEDENCIA.read_text(encoding="utf-8"))
        rutas = {item["ruta"] for item in datos["assets"]}
        self.assertIn("texturas/asfalto.jpg", rutas)
        self.assertIn("texturas/gotele.jpg", rutas)


if __name__ == "__main__":
    unittest.main()
