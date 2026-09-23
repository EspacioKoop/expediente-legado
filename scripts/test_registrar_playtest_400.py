from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_400 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-23T19:30:00+02:00",
    "participante": "tester-01",
    "plataforma": "Linux",
    "build_sha": "abc123",
    "evidencia_sha": "abc123",
    "conocimiento_previo": False,
    "respuesta_oficina": "Abrí un archivador y usé la cafetera; ambos cambiaron.",
    "interacciones_oficina": 2,
    "respuesta_calle": "Usé el portal y una persiana de la fachada respondió.",
    "interacciones_calle": 2,
    "respuesta_casa": "Probé la cómoda, la ventana y la televisión.",
    "interacciones_casa": 3,
    "respuesta_sueno": "Dos objetos deformados respondieron al examinarlos.",
    "interacciones_sueno": 2,
    "respuesta_general": "Los espacios reaccionaban y no parecían sólo decorado.",
    "feedback_inmediato": True,
    "affordances_enganosas": False,
    "ayuda_directa": False,
    "incidencia_reproducible": False,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest400Test(unittest.TestCase):
    def test_gate_cumple_con_minimos_y_checks_humanos(self):
        gate = playtest.evaluar_gate(dict(BASE))
        self.assertTrue(gate["evidencia_misma_build"])
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["oficina_reactiva"])
        self.assertTrue(gate["calle_reactiva"])
        self.assertTrue(gate["casa_reactiva"])
        self.assertTrue(gate["sueno_reactivo"])
        self.assertTrue(gate["feedback_inmediato"])
        self.assertTrue(gate["sin_affordances_enganosas"])
        self.assertTrue(gate["sin_ayuda_directa"])
        self.assertTrue(gate["sin_incidencia"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_evidencia_de_otro_sha_impide_cierre(self):
        gate = playtest.evaluar_gate(dict(BASE, evidencia_sha="otro-sha"))
        self.assertFalse(gate["evidencia_misma_build"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_conocimiento_previo_impide_usar_el_pase_como_gate(self):
        gate = playtest.evaluar_gate(dict(BASE, conocimiento_previo=True))
        self.assertFalse(gate["participante_nuevo"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_cada_fase_tiene_un_minimo_distinto(self):
        casos = (
            ("interacciones_oficina", 1, "oficina_reactiva"),
            ("interacciones_calle", 1, "calle_reactiva"),
            ("interacciones_casa", 2, "casa_reactiva"),
            ("interacciones_sueno", 1, "sueno_reactivo"),
        )
        for campo, valor, check in casos:
            with self.subTest(campo=campo):
                gate = playtest.evaluar_gate(dict(BASE, **{campo: valor}))
                self.assertFalse(gate[check])
                self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_affordance_enganosa_o_ayuda_directa_bloquean_cierre(self):
        affordance = playtest.evaluar_gate(dict(BASE, affordances_enganosas=True))
        ayuda = playtest.evaluar_gate(dict(BASE, ayuda_directa=True))
        self.assertFalse(affordance["sin_affordances_enganosas"])
        self.assertFalse(affordance["listo_para_valorar_cierre"])
        self.assertFalse(ayuda["sin_ayuda_directa"])
        self.assertFalse(ayuda["listo_para_valorar_cierre"])

    def test_feedback_o_incidencia_bloquean_cierre(self):
        sin_feedback = playtest.evaluar_gate(dict(BASE, feedback_inmediato=False))
        incidencia = playtest.evaluar_gate(dict(BASE, incidencia_reproducible=True))
        self.assertFalse(sin_feedback["feedback_inmediato"])
        self.assertFalse(sin_feedback["listo_para_valorar_cierre"])
        self.assertFalse(incidencia["sin_incidencia"])
        self.assertFalse(incidencia["listo_para_valorar_cierre"])

    def test_informe_conserva_respuestas_y_declara_limite(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("Abrí un archivador y usé la cafetera", informe)
        self.assertIn("Los espacios reaccionaban", informe)
        self.assertIn("evidencia densidad #282 SHA: `abc123`", informe)
        self.assertIn("oficina ≥2 respuestas distintas: **CUMPLE**", informe)
        self.assertIn("casa ≥3 respuestas distintas: **CUMPLE**", informe)
        self.assertIn("listo para valorar cierre de #400: **SÍ**", informe)
        self.assertIn("no interpreta las respuestas por IA", informe)


if __name__ == "__main__":
    unittest.main()
