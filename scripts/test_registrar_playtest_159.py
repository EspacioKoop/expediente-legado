from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_159 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-18T14:40:00+02:00",
    "participante": "tester-mando-01",
    "plataforma": "Linux",
    "build_sha": "abc123",
    "mando_modelo": "Xbox Wireless Controller",
    "mando_familia": "Xbox",
    "conexion": "Bluetooth",
    "remapeado": False,
    "mando_detectado": True,
    "entrada_solo_mando": True,
    "stick_apunta": True,
    "cruceta_apunta": True,
    "sin_deriva": True,
    "boton_principal_lanza": True,
    "dos_lanzamientos": True,
    "boton_secundario_abandona": True,
    "oficina_restaurada": True,
    "repeticion_funciona": True,
    "sin_incidencia_reproducible": True,
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest159Test(unittest.TestCase):
    def test_gate_solo_cumple_con_todos_los_checks_fisicos(self):
        gate = playtest.evaluar_gate(dict(BASE))
        for clave in playtest.CHECKS:
            with self.subTest(clave=clave):
                self.assertTrue(gate[clave])
        self.assertTrue(gate["listo_para_cerrar_mando"])

    def test_un_control_que_falla_bloquea_el_gate(self):
        for clave in playtest.CHECKS:
            with self.subTest(clave=clave):
                gate = playtest.evaluar_gate(dict(BASE, **{clave: False}))
                self.assertFalse(gate[clave])
                self.assertFalse(gate["listo_para_cerrar_mando"])

    def test_informe_conserva_hardware_y_declara_limite(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("Xbox Wireless Controller", informe)
        self.assertIn("Bluetooth", informe)
        self.assertIn("build SHA: `abc123`", informe)
        self.assertIn("gate físico de mando de #159: **CUMPLE**", informe)
        self.assertIn("No simula un mando físico", informe)

    def test_incidencia_reproducible_queda_visible(self):
        datos = dict(
            BASE,
            sin_incidencia_reproducible=False,
            incidencia="El botón secundario deja la cámara capturada.",
        )
        informe = playtest.render_markdown(datos)
        self.assertIn("El botón secundario deja la cámara capturada.", informe)
        self.assertIn("gate físico de mando de #159: **PENDIENTE**", informe)


if __name__ == "__main__":
    unittest.main()
