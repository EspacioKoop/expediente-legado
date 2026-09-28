from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_281 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-28T21:00:00+02:00",
    "participante": "tester-281",
    "plataforma": "Linux",
    "build_sha": "abc281",
    "control": "mando físico",
    "primera_accion_segundos": 34.5,
    "estado_0_2_visible": True,
    "feedback_1_2_claro": True,
    "gato_reorienta": True,
    "reentrada_no_duplica": True,
    "transicion_2_2": True,
    "sin_salida_oculta": True,
    "tiempo_no_ruta_normal": True,
    "export_real": True,
    "persistencia_reapertura": True,
    "sin_incidencia_bloqueante": True,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest281Test(unittest.TestCase):
    def test_pase_completo_deja_el_issue_cerrable(self):
        gate = playtest.evaluar_gate(dict(BASE))
        self.assertTrue(gate["primera_accion_menos_60s"])
        self.assertTrue(gate["issue_cerrable"])

    def test_sesenta_segundos_no_cumple_el_criterio_menos_de_un_minuto(self):
        gate = playtest.evaluar_gate(dict(BASE, primera_accion_segundos=60))
        self.assertFalse(gate["primera_accion_menos_60s"])
        self.assertFalse(gate["issue_cerrable"])

    def test_cualquier_check_humano_pendiente_bloquea_cierre(self):
        for clave in playtest.CHECKS:
            with self.subTest(clave=clave):
                gate = playtest.evaluar_gate(dict(BASE, **{clave: False}))
                self.assertFalse(gate["issue_cerrable"])

    def test_informe_declara_que_no_sustituye_el_pase_humano(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("#281 cerrable con esta evidencia: **SÍ**", informe)
        self.assertIn("CI/headless no sustituye comprensión", informe)
        self.assertIn("34.5 s", informe)


if __name__ == "__main__":
    unittest.main()
