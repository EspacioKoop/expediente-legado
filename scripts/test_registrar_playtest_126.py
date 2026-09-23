from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_126 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-18T14:30:00+02:00",
    "participante": "tester-01",
    "plataforma": "Linux",
    "build_sha": "abc123",
    "gate_visual_sha": "abc123",
    "conocimiento_previo": False,
    "respuesta_lugar": "Parece una oficina con archivo.",
    "respuesta_zonas": "Mesas de trabajo, archivadores y una zona de café.",
    "respuesta_recorrido": "No, encontré la salida y pude pasar entre las mesas.",
    "respuesta_tecnica": "No, parece un sitio de trabajo usado.",
    "lugar_reconocido": True,
    "zonas_reconocidas": True,
    "salida_encontrada": True,
    "recorrido_claro": True,
    "problema_sala_tecnica": False,
    "incidencia_reproducible": False,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest126Test(unittest.TestCase):
    def test_gate_cumple_solo_con_todos_los_checks_humanos(self):
        gate = playtest.evaluar_gate(dict(BASE))
        self.assertTrue(gate["evidencia_misma_build"])
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["lugar_reconocido"])
        self.assertTrue(gate["zonas_reconocidas"])
        self.assertTrue(gate["salida_encontrada"])
        self.assertTrue(gate["recorrido_claro"])
        self.assertTrue(gate["sin_lectura_tecnica"])
        self.assertTrue(gate["sin_incidencia"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_gate_visual_de_otro_sha_impide_cierre(self):
        gate = playtest.evaluar_gate(dict(BASE, gate_visual_sha="otro-sha"))
        self.assertFalse(gate["evidencia_misma_build"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_conocimiento_previo_impide_usar_el_pase_como_gate(self):
        gate = playtest.evaluar_gate(dict(BASE, conocimiento_previo=True))
        self.assertFalse(gate["participante_nuevo"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_sala_tecnica_reproducible_bloquea_el_cierre(self):
        gate = playtest.evaluar_gate(dict(BASE, problema_sala_tecnica=True))
        self.assertFalse(gate["sin_lectura_tecnica"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_problema_de_recorrido_bloquea_el_cierre(self):
        gate = playtest.evaluar_gate(
            dict(BASE, recorrido_claro=False, incidencia_reproducible=True)
        )
        self.assertFalse(gate["recorrido_claro"])
        self.assertFalse(gate["sin_incidencia"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_informe_conserva_respuestas_y_declara_limite(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("Parece una oficina con archivo.", informe)
        self.assertIn("Mesas de trabajo, archivadores y una zona de café.", informe)
        self.assertIn("gate visual SHA: `abc123`", informe)
        self.assertIn("gate visual y build corresponden al mismo SHA: **CUMPLE**", informe)
        self.assertIn("listo para valorar cierre de #126: **SÍ**", informe)
        self.assertIn("no interpreta las respuestas por IA", informe)


if __name__ == "__main__":
    unittest.main()
