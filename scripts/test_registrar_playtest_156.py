from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_156 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-28T20:30:00+02:00",
    "participante": "tester-ronda",
    "plataforma": "Linux",
    "build_sha": "abc156",
    "mando_modelo": "Mando USB",
    "oferta_comprensible": True,
    "puntos_fisicos_claros": True,
    "recorrido_completo": True,
    "progreso_visible": True,
    "abandono_seguro": True,
    "jornada_continua": True,
    "rehidratacion_correcta": True,
    "opt_out_funciona": True,
    "mando_fisico": True,
    "foco_mando": True,
    "sin_incidencia_bloqueante": True,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest156Test(unittest.TestCase):
    def test_gate_exige_todos_los_checks(self):
        self.assertTrue(playtest.evaluar_gate(dict(BASE))["listo_para_valorar_cierre"])
        for clave in playtest.CHECKS:
            with self.subTest(clave=clave):
                gate = playtest.evaluar_gate(dict(BASE, **{clave: False}))
                self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_informe_identifica_build_y_limite_humano(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("build SHA: `abc156`", informe)
        self.assertIn("Mando USB", informe)
        self.assertIn("listo para valorar cierre de #156: **SÍ**", informe)
        self.assertIn("no simula comprensión, gamefeel ni un mando físico", informe)

    def test_incidencia_bloqueante_impide_cierre(self):
        informe = playtest.render_markdown(
            dict(
                BASE,
                sin_incidencia_bloqueante=False,
                incidencia="El foco se pierde al volver de la lámpara.",
            )
        )
        self.assertIn("listo para valorar cierre de #156: **NO**", informe)
        self.assertIn("El foco se pierde al volver de la lámpara.", informe)


if __name__ == "__main__":
    unittest.main()
