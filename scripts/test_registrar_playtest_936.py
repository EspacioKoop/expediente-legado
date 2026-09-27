import importlib.util
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("registrar_playtest_936.py")
spec = importlib.util.spec_from_file_location("registrar_playtest_936", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


def datos_base(valor: bool = True) -> dict[str, object]:
    escenarios = {}
    for clave, _titulo in modulo.ESCENARIOS:
        registro = {nombre: valor for nombre, _ in modulo.CHECKS_COMUNES}
        if clave != "base":
            registro.update({nombre: valor for nombre, _ in modulo.CHECKS_COMPROMISO})
        registro["evidencia"] = f"docs/playtests/936-{clave}.png" if valor else ""
        registro["observaciones"] = ""
        escenarios[clave] = registro
    return {
        "fecha": "2026-09-27T21:00:00+02:00",
        "tester": "tester",
        "plataforma": "Linux",
        "build_sha": "abc1234",
        "escenarios": escenarios,
        "matriz_teclado_completa": valor,
        "reduccion_movimiento_equivalente": valor,
        "muestra_mando_fisico": False,
        "observaciones_generales": "",
    }


class RegistrarPlaytest936Test(unittest.TestCase):
    def test_matriz_contiene_base_voto_y_tregua(self):
        self.assertEqual(
            [clave for clave, _ in modulo.ESCENARIOS],
            ["base", "no_iniciar", "tregua"],
        )

    def test_gate_completo_requiere_juicio_humano_y_evidencia(self):
        gate = modulo.evaluar_registro(datos_base(True))
        self.assertTrue(gate["compromisos_ok"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_un_coste_no_percibido_mantiene_issue_pendiente(self):
        datos = datos_base(True)
        datos["escenarios"]["no_iniciar"]["coste"] = False
        gate = modulo.evaluar_registro(datos)
        self.assertFalse(gate["compromisos_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_falta_de_evidencia_no_se_oculta_con_checks(self):
        datos = datos_base(True)
        datos["escenarios"]["tregua"]["evidencia"] = ""
        gate = modulo.evaluar_registro(datos)
        self.assertFalse(gate["evidencias_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_mando_es_informativo_no_gate_de_936(self):
        datos = datos_base(True)
        datos["muestra_mando_fisico"] = False
        self.assertTrue(modulo.evaluar_registro(datos)["listo_para_valorar_cierre"])

    def test_markdown_no_puntua_credos(self):
        texto = modulo.render_markdown(datos_base(True))
        self.assertIn("Compromiso · no iniciar agresión", texto)
        self.assertIn("Compromiso · tregua mutua", texto)
        self.assertIn("claridad, coste y utilidad contextual", texto)
        self.assertIn("no compara credos", texto)
        self.assertIn("**SÍ**", texto)


if __name__ == "__main__":
    unittest.main()
