import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("registrar_playtest_513.py")
spec = importlib.util.spec_from_file_location("registrar_playtest_513", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


def datos_base(valor: bool = True) -> dict[str, object]:
    folios = {
        folio: {
            "cabecera_visible": valor,
            "lectura_completa": valor,
            "sin_recorte": valor,
            "desplazamiento_ok": valor,
            "captura": f"docs/playtests/capturas/{folio}.png",
            "notas": "",
        }
        for folio, _tipo in modulo.FOLIOS
    }
    return {
        "fecha": "2026-09-17T20:00:00+02:00",
        "tester": "tester",
        "plataforma": "Linux",
        "build_sha": "abc1234",
        "folios": folios,
        "gatillo_memo_ok": valor,
        "gatillo_ficha_ok": valor,
        "peritaje_no_conclusion": valor,
        "acta_no_conclusion": valor,
        "relectura_sin_coste": valor,
        "relaciones_no_automaticas": valor,
        "incidencia": "",
        "observaciones": "",
    }


class RegistrarPlaytest513Test(unittest.TestCase):
    def test_gate_cumple_solo_si_todos_los_checks_cumplen(self):
        gate = modulo.evaluar_gate(datos_base(True))
        self.assertTrue(gate["folios_ok"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["gatillos_ok"])
        self.assertTrue(gate["semantica_ok"])
        self.assertTrue(gate["economia_ok"])
        self.assertTrue(gate["relaciones_ok"])
        self.assertTrue(gate["listo_para_cerrar"])

    def test_un_folio_incompleto_bloquea_el_cierre(self):
        datos = datos_base(True)
        datos["folios"]["MEMO-1999-088"]["lectura_completa"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["folios_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_folio_ausente_bloquea_el_cierre(self):
        datos = datos_base(True)
        del datos["folios"]["ACTA-1999-014"]
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["folios_ok"])
        self.assertFalse(gate["evidencias_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_captura_ausente_bloquea_el_cierre(self):
        datos = datos_base(True)
        datos["folios"]["F-1999-00231"]["captura"] = "   "
        gate = modulo.evaluar_gate(datos)
        self.assertTrue(gate["folios_ok"])
        self.assertFalse(gate["evidencias_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_una_relacion_automatica_bloquea_el_cierre(self):
        datos = datos_base(True)
        datos["relaciones_no_automaticas"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["relaciones_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_markdown_traza_build_viewport_y_los_cuatro_folios(self):
        texto = modulo.render_markdown(datos_base(True))
        self.assertIn("build SHA: `abc1234`", texto)
        self.assertIn("viewport: `1920×1080`", texto)
        self.assertIn("evidencia visual adjunta para los cuatro folios: **CUMPLE**", texto)
        for folio, _tipo in modulo.FOLIOS:
            self.assertIn(folio, texto)
        self.assertIn("listo para valorar cierre de #513: **SÍ**", texto)


if __name__ == "__main__":
    unittest.main()
