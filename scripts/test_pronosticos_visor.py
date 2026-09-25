import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
VISOR = (ROOT / "godot/guion/visor_pronosticos_app.gd").read_text(encoding="utf-8")
ESCENA = (ROOT / "godot/escenas/visor.tscn").read_text(encoding="utf-8")
TEXTOS = (ROOT / "godot/datos/textos.csv").read_text(encoding="utf-8")
RECORRIDO = (ROOT / "godot/pruebas/recorrido.gd").read_text(encoding="utf-8")
PRUEBA_GODOT = "res://pruebas/pruebas_pronosticos_visor.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class PronosticosVisorTests(unittest.TestCase):
    def test_el_visormonta_la_capa_sin_reemplazar_verticales_previas(self):
        self.assertIn('extends "res://guion/visor_anexos_app.gd"', VISOR)
        self.assertIn('path="res://guion/visor_pronosticos_app.gd"', ESCENA)
        self.assertIn(
            'preload("res://guion/visor_pronosticos_app.gd")',
            RECORRIDO,
        )

    def test_la_exposicion_se_deriva_de_lecturas_reales(self):
        self.assertIn('jornada.get("leidos_total", [])', VISOR)
        self.assertIn('jornada.get("leido_hoy", [])', VISOR)
        self.assertIn("func _caso_expuesto() -> bool:", VISOR)
        self.assertIn("Pronosticos.crear(", VISOR)
        self.assertIn("Pronosticos.abandonar(", VISOR)

    def test_la_tarjeta_es_opcional_y_localizada(self):
        self.assertIn("VISOR_PRONOSTICO_TITULO,PRONÓSTICO DE AUDITORÍA", TEXTOS)
        self.assertIn("VISOR_PRONOSTICO_DISPONIBLE,Opcional", TEXTOS)
        self.assertIn("VISOR_PRONOSTICO_BLOQUEADO,", TEXTOS)
        self.assertIn('"documento_clave"', VISOR)
        self.assertIn('PanelPronosticoAuditoria', VISOR)
        self.assertIn("EstiloSiga.caja_saliente(EstiloSiga.PAPEL)", VISOR)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 13, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
