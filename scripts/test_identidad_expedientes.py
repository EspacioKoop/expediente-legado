from pathlib import Path
import json
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "identidad_expedientes.json"
VISOR = ROOT / "godot" / "guion" / "visor_identidad_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "visor.tscn"


class IdentidadExpedientesTest(unittest.TestCase):
    def test_catalogo_y_assets_se_validan_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_identidad_expedientes.gd",
            "39 pasadas, 0 fallos",
        )

    def test_hay_nueve_identidades_distintas(self):
        catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        self.assertEqual(len(catalogo), 9)
        self.assertEqual(len({ficha["icono"] for ficha in catalogo.values()}), 9)
        self.assertEqual(len({ficha["acento"] for ficha in catalogo.values()}), 9)
        for ficha in catalogo.values():
            self.assertTrue(ficha["codigo"])
            self.assertTrue(ficha["motivo"])
            self.assertTrue(ficha["icono"].startswith("res://arte/siga_expedientes/"))

    def test_el_visor_aplica_identidad_sin_tocar_reglas_de_juego(self):
        codigo = VISOR.read_text(encoding="utf-8")
        self.assertIn('extends "res://guion/visor_anexos_app.gd"', codigo)
        self.assertIn("_archivo.set_item_icon", codigo)
        self.assertIn("_actualizar_identidad()", codigo)
        self.assertNotIn("gastar_accion", codigo)
        self.assertNotIn("gastar_lectura", codigo)
        self.assertNotIn("Acusacion.acusar", codigo)

    def test_la_escena_activa_la_capa_de_identidad(self):
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/visor_identidad_app.gd"', escena)


if __name__ == "__main__":
    unittest.main()
