from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_157 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-28T20:20:00+02:00",
    "participante": "tester-01",
    "plataforma": "Linux",
    "build_sha": "abc123",
    "mando_modelo": "Mando USB",
    "conexion": "cable",
    "dos_carpetas": True,
    "recogida_clara": True,
    "error_no_destruye": True,
    "correccion_funciona": True,
    "siguiente_carpeta": True,
    "abandono_persiste": True,
    "jornada_continua": True,
    "rehidratacion_comprensible": True,
    "precision_visible": True,
    "mando_fisico": True,
    "foco_mando": True,
    "sin_incidencia_bloqueante": True,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest157Test(unittest.TestCase):
    def test_gate_exige_todos_los_checks(self):
        gate = playtest.evaluar_gate(dict(BASE))
        self.assertTrue(gate["listo_para_cerrar_gate_humano"])
        for clave in playtest.CHECKS:
            with self.subTest(clave=clave):
                roto = playtest.evaluar_gate(dict(BASE, **{clave: False}))
                self.assertFalse(roto["listo_para_cerrar_gate_humano"])

    def test_informe_identifica_build_hardware_y_limite(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("build SHA: `abc123`", informe)
        self.assertIn("Mando USB", informe)
        self.assertIn("gate humano de #157: **CUMPLE**", informe)
        self.assertIn("no simulan comprensión, gamefeel ni hardware físico", informe)

    def test_incidencia_bloquea_y_queda_visible(self):
        informe = playtest.render_markdown(
            dict(
                BASE,
                sin_incidencia_bloqueante=False,
                incidencia="Al salir con carpeta pendiente se captura el ratón.",
            )
        )
        self.assertIn("gate humano de #157: **PENDIENTE**", informe)
        self.assertIn("Al salir con carpeta pendiente se captura el ratón.", informe)


if __name__ == "__main__":
    unittest.main()
