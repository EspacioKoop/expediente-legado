import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
VECINOS = ROOT / "godot" / "guion" / "vecinos_edificio.gd"
DOC = ROOT / "docs" / "vecinos-edificio.md"
PRUEBA_GODOT = "pruebas/pruebas_vecinos_edificio.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class VecinosEdificioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vecinos = VECINOS.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_roster_minimo_y_presencias_no_visibles(self):
        for presencia in (
            '"manuela_3b"',
            '"televisor_2a"',
            '"pasos_4a"',
            '"repartidor_confundido"',
        ):
            self.assertIn(presencia, self.vecinos)
        self.assertGreaterEqual(self.vecinos.count('"modo": "sonoro"'), 2)
        self.assertIn('"modo": "visible"', self.vecinos)

    def test_calendario_es_declarativo_y_acotado_al_trayecto(self):
        self.assertIn('jornada.get("fase", "")', self.vecinos)
        self.assertIn('!= "trayecto"', self.vecinos)
        self.assertIn('"inicio":', self.vecinos)
        self.assertIn('"periodo":', self.vecinos)
        self.assertIn("_indice_ocurrencia", self.vecinos)

    def test_hay_cambios_ambientales_y_reduccion_de_movimiento(self):
        for contrato in ("FELPUDOS", "NOTAS_TABLON", '"luz_portal"', '"puerta_2a"'):
            self.assertIn(contrato, self.vecinos)
        self.assertIn('"estatico" if reduccion_movimiento else movimiento', self.vecinos)
        self.assertIn('"reduccion_movimiento": reduccion_movimiento', self.vecinos)

    def test_paquete_es_no_dialogado_idempotente_y_sin_economia(self):
        self.assertIn('const ID_PAQUETE_EQUIVOCADO := "paquete_equivocado_4a"', self.vecinos)
        self.assertIn('"dialogo": false', self.vecinos)
        self.assertIn('"verbo": "coger"', self.vecinos)
        self.assertIn('"correo_postal": "buzon_portal"', self.vecinos)
        self.assertIn("resueltos.has(clave)", self.vecinos)
        self.assertIn('"bloquea_campana": false', self.vecinos)
        self.assertNotIn("Jornada.gastar", self.vecinos)
        self.assertNotIn('jornada["dinero"]', self.vecinos)
        for campo_social in ('"afinidad"', '"reputacion"', '"romance"'):
            self.assertNotIn(campo_social, self.vecinos.lower())

    def test_no_hardcodea_teclas_y_documenta_el_siguiente_corte(self):
        for patron in ("KEY_", "physical_keycode", "is_key_pressed"):
            self.assertNotIn(patron, self.vecinos)
        for referencia in ("#96", "#181", "#669", "#672", "#673"):
            self.assertIn(referencia, self.doc)
        self.assertIn("standalone first", self.doc.lower())
        self.assertIn("dia.tscn", self.doc)

    def test_vertical_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importacion = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--editor",
                "--import",
                "--quit",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(importacion.returncode, 0, importacion.stdout)

        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 35, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
