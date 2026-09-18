import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
RESOLVER = (ROOT / "godot/guion/pronosticos_auditoria.gd").read_text(encoding="utf-8")
VISOR = (ROOT / "godot/guion/visor_pronosticos_app.gd").read_text(encoding="utf-8")
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
ASCENSOR = (ROOT / "godot/guion/dia_ascensor_app.gd").read_text(encoding="utf-8")
PRUEBA_GODOT = "res://pruebas/pruebas_pronosticos_resolucion.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class PronosticosResolucionTests(unittest.TestCase):
    def test_la_firma_resuelve_antes_del_guardado_heredado(self):
        resolver = "PronosticosAuditoria.resolver_cierre(partida.estado, caso, resultado)"
        self.assertIn(resolver, VISOR)
        self.assertLess(VISOR.index(resolver), VISOR.index("super._al_firmar(resultado, formulario)"))

    def test_las_dos_salidas_resuelven_antes_de_fichar(self):
        resolver = "PronosticosAuditoria.resolver_fin_jornada(partida.estado)"
        for codigo in (DIA, ASCENSOR):
            self.assertIn(resolver, codigo)
            self.assertLess(codigo.index(resolver), codigo.index("Jornada.fichar_salida(jornada)"))

    def test_el_resolver_solo_lee_hechos_existentes(self):
        for hecho in (
            'acusacion.get("duelo"',
            'acusacion.get("precipitada"',
            'estado.get("pistas_descubiertas"',
            '"registroOrigen"',
            "Acusacion.esta_cerrado",
        ):
            self.assertIn(hecho, RESOLVER)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 16, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
