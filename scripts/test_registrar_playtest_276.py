from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_276 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-28T21:20:00+02:00",
    "participante": "tester-276",
    "plataforma": "Linux",
    "build_sha": "abc276",
    "control": "teclado/ratón",
    "evidencia_frontal": "capturas/276-frontal.png",
    "evidencia_lateral": "capturas/276-lateral.png",
    "evidencia_reduccion": "capturas/276-reduccion.png",
    "export_real": True,
    "frontal_atribucion_inmediata": True,
    "lateral_atribucion_inmediata": True,
    "movimiento_durante_linea": True,
    "dos_companeros_sin_ambiguedad": True,
    "camara_restaura": True,
    "sin_conflicto_hud": True,
    "sonido_no_molesta": True,
    "reduccion_movimiento_correcta": True,
    "sin_incidencia_bloqueante": True,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest276Test(unittest.TestCase):
    def test_pase_completo_deja_issue_cerrable(self):
        self.assertTrue(playtest.evaluar_gate(dict(BASE))["issue_cerrable"])

    def test_falta_de_evidencia_bloquea_cierre(self):
        for campo in ("evidencia_frontal", "evidencia_lateral", "evidencia_reduccion"):
            with self.subTest(campo=campo):
                gate = playtest.evaluar_gate(dict(BASE, **{campo: ""}))
                self.assertFalse(gate["issue_cerrable"])

    def test_cualquier_check_humano_bloquea_cierre(self):
        for clave in playtest.CHECKS:
            with self.subTest(clave=clave):
                gate = playtest.evaluar_gate(dict(BASE, **{clave: False}))
                self.assertFalse(gate["issue_cerrable"])

    def test_informe_separa_ci_de_percepcion(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("#276 cerrable con esta evidencia: **SÍ**", informe)
        self.assertIn("CI puede comprobar", informe)
        self.assertIn("no si el hablante se", informe)


if __name__ == "__main__":
    unittest.main()
