from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_395 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-16T14:00:00+02:00",
    "participante": "tester-01",
    "plataforma": "Linux",
    "build_sha": "abc123",
    "conocimiento_previo": False,
    "entrada_lugar_respuesta": "Una oficina o archivo.",
    "entrada_rol_respuesta": "Soy quien revisa expedientes.",
    "entrada_tarea_respuesta": "Tengo que empezar a revisar el trabajo asignado.",
    "entrada_lugar_correcto": True,
    "entrada_rol_correcto": True,
    "entrada_tarea_correcta": True,
    "entrada_ritmo": "bien",
    "trayecto_continuidad_respuesta": "Salgo del archivo y el ascensor me lleva hacia la calle.",
    "trayecto_continuidad_correcta": True,
    "trayecto_ritmo": "bien",
    "trayecto_sincronia": "bien",
    "sueno_causa_respuesta": "Me he dormido al usar la cama.",
    "sueno_causa_correcta": True,
    "sueno_ritmo": "bien",
    "problema_reproducible": False,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest395Test(unittest.TestCase):
    def test_gate_cumple_solo_con_checks_humanos_completos(self):
        gate = playtest.evaluar_gate(dict(BASE))
        self.assertTrue(gate["participante_nuevo"])
        self.assertTrue(gate["comprension_entrada"])
        self.assertTrue(gate["comprension_trayecto"])
        self.assertTrue(gate["comprension_sueno"])
        self.assertTrue(gate["ritmo_sin_bloqueo"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_conocimiento_previo_impide_usar_el_pase_como_gate(self):
        datos = dict(BASE, conocimiento_previo=True)
        gate = playtest.evaluar_gate(datos)
        self.assertFalse(gate["participante_nuevo"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_un_fallo_de_comprension_mantiene_el_issue_pendiente(self):
        datos = dict(BASE, entrada_tarea_correcta=False)
        gate = playtest.evaluar_gate(datos)
        self.assertFalse(gate["comprension_entrada"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_fallo_de_continuidad_trayecto_bloquea_el_cierre(self):
        datos = dict(BASE, trayecto_continuidad_correcta=False)
        gate = playtest.evaluar_gate(datos)
        self.assertFalse(gate["comprension_trayecto"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_problema_reproducible_bloquea_el_cierre(self):
        datos = dict(BASE, problema_reproducible=True)
        gate = playtest.evaluar_gate(datos)
        self.assertFalse(gate["ritmo_sin_bloqueo"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_informe_conserva_respuestas_y_declara_limite(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("Una oficina o archivo.", informe)
        self.assertIn("Salgo del archivo y el ascensor me lleva hacia la calle.", informe)
        self.assertIn("sincronía audiovisual percibida: bien", informe)
        self.assertIn("Me he dormido al usar la cama.", informe)
        self.assertIn("listo para valorar cierre de #395: **SÍ**", informe)
        self.assertIn("no interpreta las respuestas por IA", informe)


if __name__ == "__main__":
    unittest.main()
