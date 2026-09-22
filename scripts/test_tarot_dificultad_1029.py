import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "godot" / "guion" / "menu_global.gd"
ACUSACION = ROOT / "godot" / "guion" / "acusacion.gd"
PROMETEO = ROOT / "godot" / "guion" / "prometeo.gd"
DATOS = ROOT / "godot" / "datos" / "menu_dificultad_textos.json"
PRUEBA_GODOT = "pruebas/pruebas_tarot_dificultad_1029.gd"
RESUMEN = re.compile(r"tarot_dificultad_1029: (\d+) pasadas, 0 fallos")


class TarotDificultad1029Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = MENU.read_text(encoding="utf-8")
        cls.acusacion = ACUSACION.read_text(encoding="utf-8")
        cls.prometeo = PROMETEO.read_text(encoding="utf-8")
        cls.datos = json.loads(DATOS.read_text(encoding="utf-8"))

    def test_selector_usa_datos_y_ids_canonicos(self):
        self.assertIn(
            'const RUTA_TEXTOS_DIFICULTAD := "res://datos/menu_dificultad_textos.json"',
            self.menu,
        )
        self.assertEqual(
            [opcion["id"] for opcion in self.datos["opciones"]],
            ["facil", "normal", "dificil"],
        )
        for dificultad in ("facil", "normal", "dificil"):
            self.assertIn(f'"{dificultad}":', self.acusacion)

    def test_refrescar_ui_no_es_un_emisor_de_tarot(self):
        inicio = self.menu.index("func _refrescar_dificultad()")
        fin = self.menu.index("func _actualizar_detalle_dificultad(", inicio)
        bloque = self.menu[inicio:fin]
        self.assertIn("_dificultad.select(indice)", bloque)
        self.assertNotIn("cambiar_dificultad", bloque)
        self.assertNotIn("desbloquear_carta", bloque)

    def test_evento_real_cambia_sincroniza_mundo_y_guarda(self):
        inicio = self.menu.index("func _al_cambiar_dificultad(")
        fin = self.menu.index("func _montar_preferencias_camara(", inicio)
        bloque = self.menu[inicio:fin]
        cambio = bloque.index("Acusacion.cambiar_dificultad")
        mundo = bloque.index("Prometeo.sincronizar_tarot_mundo")
        guardado = bloque.index("partida_actual.guardar()")
        self.assertLess(cambio, mundo)
        self.assertLess(mundo, guardado)

    def test_dominio_delega_la_fuerza_en_frontera_comun(self):
        inicio = self.acusacion.index("static func cambiar_dificultad(")
        fin = self.acusacion.index("## El veredicto firmado", inicio)
        bloque = self.acusacion[inicio:fin]
        self.assertIn('DIFICULTADES.has(nueva)', bloque)
        self.assertIn('estado["dificultad"] = nueva', bloque)
        self.assertIn('estado["vida"] = mini(', bloque)
        self.assertIn("Prometeo.sincronizar_tarot_por_dificultad(estado)", bloque)

        inicio = self.prometeo.index("static func sincronizar_tarot_por_dificultad(")
        fin = self.prometeo.index("## Progreso por expediente", inicio)
        bloque = self.prometeo[inicio:fin]
        self.assertIn('!= "dificil"', bloque)
        self.assertIn(
            'desbloquear_carta_en_estado(estado, "la-fuerza")',
            bloque,
        )

    def test_reinicio_es_evento_real_pero_carga_no_sincroniza(self):
        inicio = self.prometeo.index("static func reiniciar_vuelta(")
        fin = self.prometeo.index("static func _lista_estado(", inicio)
        reinicio = self.prometeo[inicio:fin]
        self.assertIn("sincronizar_tarot_por_dificultad(estado)", reinicio)

        partida = (ROOT / "godot" / "guion" / "partida.gd").read_text(encoding="utf-8")
        self.assertNotIn("sincronizar_tarot_por_dificultad", partida)

    def test_comportamiento_en_godot_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
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
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 14, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
