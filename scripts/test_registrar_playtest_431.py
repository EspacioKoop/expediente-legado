import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("registrar_playtest_431.py")
spec = importlib.util.spec_from_file_location("registrar_playtest_431", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


def datos_base() -> dict[str, object]:
    return {
        "fecha": "2026-09-18T23:50:00+02:00",
        "tester": "tester",
        "plataforma": "Linux",
        "build_sha": "abc1234",
        "teclado_real": True,
        "mando_fisico": False,
        "mando_modelo": "no probado",
        "casos": [
            {
                "nombre": "caso@1",
                "folios_abiertos": 4,
                "relectura_voluntaria": True,
                "intentos_relacion": 2,
                "marcador_usado": True,
                "anexo_usado": False,
                "nota": "",
            },
            {
                "nombre": "caso2@2",
                "folios_abiertos": 3,
                "relectura_voluntaria": True,
                "intentos_relacion": 1,
                "marcador_usado": False,
                "anexo_usado": True,
                "nota": "",
            },
        ],
        "capas": {
            "relacion": True,
            "relacion_sin_ayuda": True,
            "marcador": True,
            "marcador_sin_ayuda": True,
            "metadatos": False,
            "metadatos_sin_ayuda": False,
            "anexo": True,
            "anexo_sin_ayuda": False,
        },
        "relacion_valida": True,
        "relacion_invalida_prudente": True,
        "feedback_pareja_entendido": True,
        "persisten_lecturas": True,
        "persisten_marcadores": True,
        "persisten_relaciones": True,
        "contexto_careo_visible": True,
        "careo_no_automatizado": True,
        "sin_hueco_paridad_sin_issue": True,
        "impresion": "ligera",
        "evidencia": "",
        "incidencias": "",
    }


class RegistrarPlaytest431Test(unittest.TestCase):
    def test_gate_cumple_con_dos_casos_y_dos_capas_espontaneas(self):
        gate = modulo.evaluar_gate(datos_base())
        self.assertTrue(gate["dos_casos_ok"])
        self.assertTrue(gate["capas_ok"])
        self.assertTrue(gate["relacion_ok"])
        self.assertTrue(gate["persistencia_ok"])
        self.assertTrue(gate["careo_ok"])
        self.assertTrue(gate["paridad_ok"])
        self.assertTrue(gate["experiencia_ok"])
        self.assertTrue(gate["teclado_ok"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_un_solo_expediente_bloquea_el_gate(self):
        datos = datos_base()
        datos["casos"] = datos["casos"][:1]
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["dos_casos_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_una_sola_capa_espontanea_no_basta(self):
        datos = datos_base()
        capas = datos["capas"]
        capas["marcador_sin_ayuda"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["capas_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_relacion_negativa_que_sobreafirma_bloquea(self):
        datos = datos_base()
        datos["relacion_invalida_prudente"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["relacion_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_fallo_de_persistencia_bloquea(self):
        datos = datos_base()
        datos["persisten_marcadores"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["persistencia_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_lectura_mas_decision_inmediata_bloquea(self):
        datos = datos_base()
        datos["impresion"] = "lectura"
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["experiencia_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_mando_es_evidencia_opcional_no_gate(self):
        datos = datos_base()
        datos["mando_fisico"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_markdown_traza_build_casos_y_limite_humano(self):
        texto = modulo.render_markdown(datos_base())
        self.assertIn("build SHA: `abc1234`", texto)
        self.assertIn("caso@1", texto)
        self.assertIn("caso2@2", texto)
        self.assertIn("investigación ligera pero real", texto)
        self.assertIn("listo para valorar cierre de #286: **SÍ**", texto)
        self.assertIn("CI, capturas automáticas o este script", texto)


if __name__ == "__main__":
    unittest.main()
