from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_299 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-25T11:20:00+02:00",
    "participante": "tester-01",
    "plataforma": "Linux",
    "build_sha": "abc123",
    "conocimiento_previo": False,
    "relato": "Exploró, siguió el eco, completó dos objetivos y despertó.",
    "segundos_primer_objetivo": 42,
    "ayuda_primer_objetivo": False,
    "estado_0_2_legible": True,
    "feedback_1_2": True,
    "guia_pendiente_legible": True,
    "sin_doble_conteo": True,
    "transicion_2_2": True,
    "transicion_unica": True,
    "opcional_no_bloquea": True,
    "temporizador_alternativo": True,
    "persistencia_ok": True,
    "incidencia_invalidante": False,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest299Test(unittest.TestCase):
    def test_gate_cumple_con_recorrido_humano_completo(self):
        gate = playtest.evaluar_gate(dict(BASE))
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["sin_ayuda_primer_objetivo"])
        self.assertTrue(gate["primero_menos_60"])
        self.assertTrue(gate["sin_doble_conteo"])
        self.assertTrue(gate["transicion_2_2"])
        self.assertTrue(gate["transicion_unica"])
        self.assertTrue(gate["persistencia_ok"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_sesenta_segundos_exactos_no_cumple_el_criterio(self):
        gate = playtest.evaluar_gate(dict(BASE, segundos_primer_objetivo=60))
        self.assertFalse(gate["primero_menos_60"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_ayuda_directa_invalida_el_gate_de_legibilidad(self):
        gate = playtest.evaluar_gate(dict(BASE, ayuda_primer_objetivo=True))
        self.assertFalse(gate["sin_ayuda_primer_objetivo"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_doble_conteo_o_doble_transicion_bloquean_cierre(self):
        duplicado = playtest.evaluar_gate(dict(BASE, sin_doble_conteo=False))
        transicion = playtest.evaluar_gate(dict(BASE, transicion_unica=False))
        self.assertFalse(duplicado["listo_para_valorar_cierre"])
        self.assertFalse(transicion["listo_para_valorar_cierre"])

    def test_informe_conserva_relato_y_resultado(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("Exploró, siguió el eco", informe)
        self.assertIn("Tiempo hasta el primer objetivo válido: **42 s**", informe)
        self.assertIn("primer objetivo en <60 s: **CUMPLE**", informe)
        self.assertIn("listo para valorar cierre de #299: **SÍ**", informe)
        self.assertIn("sólo de los datos/checks", informe)


if __name__ == "__main__":
    unittest.main()
