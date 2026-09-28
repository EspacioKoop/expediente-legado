from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_272 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-28T21:05:00+02:00",
    "participante": "tester-272",
    "plataforma": "Linux",
    "build_sha": "abc272",
    "conocimiento_previo": False,
    "respuesta_espacio": "Un archivo de oficina, planta 4.",
    "respuesta_puesto": "El terminal 4-B.",
    "respuesta_accion": "Ir al terminal verde y abrir SIGA.",
    "respuesta_salida": "La puerta del fondo.",
    "respuesta_tutorial": "Una instrucción.",
    "espacio_identificado": True,
    "puesto_identificado": True,
    "primera_accion_identificada": True,
    "salida_encontrada": True,
    "tutorial_no_confundido": True,
    "ayuda_externa": False,
    "incidencia_bloqueante": False,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest272Test(unittest.TestCase):
    def test_pase_limpio_deja_issue_cerrable(self):
        self.assertTrue(playtest.evaluar_gate(dict(BASE))["issue_cerrable"])

    def test_conocimiento_previo_no_sirve_como_gate(self):
        gate = playtest.evaluar_gate(dict(BASE, conocimiento_previo=True))
        self.assertFalse(gate["participante_nuevo"])
        self.assertFalse(gate["issue_cerrable"])

    def test_cualquier_fallo_observable_bloquea_cierre(self):
        campos = (
            "espacio_identificado",
            "puesto_identificado",
            "primera_accion_identificada",
            "salida_encontrada",
            "tutorial_no_confundido",
        )
        for campo in campos:
            with self.subTest(campo=campo):
                self.assertFalse(
                    playtest.evaluar_gate(dict(BASE, **{campo: False}))["issue_cerrable"]
                )

    def test_ayuda_o_incidencia_bloquean_cierre(self):
        self.assertFalse(
            playtest.evaluar_gate(dict(BASE, ayuda_externa=True))["issue_cerrable"]
        )
        self.assertFalse(
            playtest.evaluar_gate(dict(BASE, incidencia_bloqueante=True))["issue_cerrable"]
        )

    def test_informe_conserva_respuestas_y_limite(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("Un archivo de oficina, planta 4.", informe)
        self.assertIn("#272 cerrable con esta evidencia: **SÍ**", informe)
        self.assertIn("protocolo de #126", informe)
        self.assertIn("no sustituye el juicio humano", informe)


if __name__ == "__main__":
    unittest.main()
