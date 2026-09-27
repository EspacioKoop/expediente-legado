import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("registrar_playtest_957.py")
spec = importlib.util.spec_from_file_location("registrar_playtest_957", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


def datos_base() -> dict[str, object]:
    return {
        "fecha": "2026-09-27T19:55:00+02:00",
        "tester": "tester",
        "plataforma": "Linux",
        "build_sha": "abc1234",
        "zonas_probadas": 2,
        "zonas": "archivo, casa",
        "criterios": {clave: True for clave, _descripcion in modulo.CRITERIOS},
        "evidencia": "captura-suelo.png; captura-pared.png",
        "incidencias": "",
    }


class RegistrarPlaytest957Test(unittest.TestCase):
    def test_gate_cumple_con_dos_zonas_y_todos_los_criterios(self):
        gate = modulo.evaluar_gate(datos_base())

        self.assertTrue(gate["dos_zonas"])
        self.assertTrue(gate["persistencia_real"])
        self.assertTrue(gate["sin_colisiones"])
        self.assertTrue(gate["estetica_coherente"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_una_sola_zona_bloquea_aunque_el_tester_marque_si(self):
        datos = datos_base()
        datos["zonas_probadas"] = 1

        gate = modulo.evaluar_gate(datos)

        self.assertFalse(gate["dos_zonas"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_un_fallo_visual_mantiene_el_gate_pendiente(self):
        datos = datos_base()
        criterios = datos["criterios"]
        assert isinstance(criterios, dict)
        criterios["texto_local"] = False

        gate = modulo.evaluar_gate(datos)

        self.assertFalse(gate["texto_local"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_un_fallo_de_persistencia_mantiene_el_gate_pendiente(self):
        datos = datos_base()
        criterios = datos["criterios"]
        assert isinstance(criterios, dict)
        criterios["persistencia_real"] = False

        gate = modulo.evaluar_gate(datos)

        self.assertFalse(gate["persistencia_real"])
        self.assertFalse(gate["listo_para_valorar_cierre"])


    def test_zonas_sin_identificar_bloquean_el_gate(self):
        datos = datos_base()
        datos["zonas"] = "   "

        gate = modulo.evaluar_gate(datos)

        self.assertFalse(gate["zonas_identificadas"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_evidencia_vacia_bloquea_el_gate(self):
        datos = datos_base()
        datos["evidencia"] = ""

        gate = modulo.evaluar_gate(datos)

        self.assertFalse(gate["evidencia_trazable"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_markdown_traza_build_zonas_evidencia_y_limite_humano(self):
        texto = modulo.render_markdown(datos_base())

        self.assertIn("build SHA: `abc1234`", texto)
        self.assertIn("archivo, casa", texto)
        self.assertIn("captura-suelo.png; captura-pared.png", texto)
        self.assertIn("listo para valorar cierre de #957: **SÍ**", texto)
        self.assertIn("respuestas introducidas durante un pase", texto)
        self.assertIn("no validan la", texto)


if __name__ == "__main__":
    unittest.main()
