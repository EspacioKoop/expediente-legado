import json
import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]


class CorreoPostalTest(unittest.TestCase):
    def test_contrato_de_correo_postal_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_correo_postal.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("32 pasadas, 0 fallos", resultado.stdout)

    def test_integracion_no_abre_economia_paralela(self):
        correo = (ROOT / "godot" / "guion" / "correo_postal.gd").read_text()
        controlador = (ROOT / "godot" / "guion" / "dia_correo_postal_app.gd").read_text()
        escena = (ROOT / "godot" / "escenas" / "dia.tscn").read_text()

        self.assertNotIn("Jornada.gastar(", correo)
        self.assertIn("Inventario.recoger", correo)
        self.assertIn('jornada.get("fase", "")', correo)
        self.assertIn('"fuera_del_portal"', correo)
        self.assertIn('buzon.name = "BuzonPostal"', controlador)
        self.assertIn("buzon.buzon_vacio.connect(_al_buzon_vacio)", controlador)
        self.assertIn("CorreoPostalLector.new()", controlador)
        self.assertIn("get_tree().paused = true", controlador)
        self.assertIn("get_tree().paused = false", controlador)
        self.assertIn("Input.MOUSE_MODE_VISIBLE", controlador)
        self.assertIn("dia_correo_postal_app.gd", escena)

    def test_lector_es_modal_accesible_y_reutiliza_presentacion(self):
        lector = (ROOT / "godot" / "guion" / "correo_postal_lector.gd").read_text()
        textos = json.loads(
            (ROOT / "godot" / "datos" / "correo_postal_presentacion.json").read_text()
        )

        self.assertIn("extends Window", lector)
        self.assertIn("exclusive = true", lector)
        self.assertIn("RichTextLabel.new()", lector)
        self.assertIn("JOY_BUTTON_A", lector)
        self.assertIn("JOY_BUTTON_B", lector)
        self.assertIn('is_action_pressed("cancelar")', lector)
        self.assertEqual(len(textos["categorias"]), 8)
        self.assertTrue(textos["cuerpo_vacio"])

    def test_paquete_encaja_en_contrato_visual_de_casa(self):
        correo = (ROOT / "godot" / "guion" / "correo_postal.gd").read_text()
        casa = (ROOT / "godot" / "guion" / "casa_acumulacion_3d.gd").read_text()

        self.assertIn('"id": "postal_iman_calendario"', correo)
        self.assertIn('"categoria": "papel"', correo)
        self.assertIn('categoria in ["documento", "papel"]', casa)
        self.assertNotIn("Inventario.guardar_en_casa", correo)


if __name__ == "__main__":
    unittest.main()
