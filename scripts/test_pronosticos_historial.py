import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
VISOR = (ROOT / "godot/guion/visor_pronosticos_app.gd").read_text(encoding="utf-8")
TEXTOS = (ROOT / "godot/datos/textos.csv").read_text(encoding="utf-8")
PRUEBA_GODOT = "res://pruebas/pruebas_pronosticos_historial.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class PronosticosHistorialTests(unittest.TestCase):
    def test_el_boton_abre_el_historial_persistido(self):
        self.assertIn('pressed.connect(_abrir_historial_pronosticos)', VISOR)
        inicio = VISOR.index("func _abrir_historial_pronosticos()")
        fin = VISOR.index("func _cerrar_historial_pronosticos()", inicio)
        bloque = VISOR[inicio:fin]
        self.assertIn("Pronosticos.historial", bloque)
        self.assertIn("set_item_metadata", bloque)

    def test_consulta_es_solo_lectura(self):
        inicio = VISOR.index("func _abrir_historial_pronosticos()")
        fin = VISOR.index("func _actualizar_pronostico()", inicio)
        bloque = VISOR[inicio:fin]
        for prohibido in (
            "Pronosticos.crear(",
            "Pronosticos.abandonar(",
            "Pronosticos.resolver(",
            "_guardar_o_avisar(",
            "partida.guardar(",
        ):
            self.assertNotIn(prohibido, bloque)

    def test_textos_del_historial_existen(self):
        for clave in (
            "VISOR_PRONOSTICO_HISTORIAL,",
            "VISOR_PRONOSTICO_HISTORIAL_AYUDA,",
            "VISOR_PRONOSTICO_HISTORIAL_FILA,",
            "VISOR_PRONOSTICO_HISTORIAL_TITULO,",
            "VISOR_PRONOSTICO_HISTORIAL_VACIO,",
        ):
            self.assertIn(clave, TEXTOS)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 10, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
