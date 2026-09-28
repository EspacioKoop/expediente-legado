import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("registrar_playtest_666.py")
spec = importlib.util.spec_from_file_location("registrar_playtest_666", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


def datos_base(valor: bool = True) -> dict[str, object]:
    escenarios = {}
    for clave, _titulo, checks in modulo.ESCENARIOS:
        registro = {nombre: valor for nombre, _descripcion in checks}
        registro["evidencia"] = f"docs/playtests/chat-{clave}.png" if valor else ""
        registro["notas"] = ""
        escenarios[clave] = registro

    return {
        "fecha": "2026-09-28T22:35:00+02:00",
        "tester": "tester",
        "plataforma": "Linux",
        "build_sha": "abc1234",
        "viewport": "1920x1080",
        "teclado_real": valor,
        "mando_fisico": valor,
        "mando_modelo": "mando USB",
        "reduccion_movimiento_probada": valor,
        "escenarios": escenarios,
        "incidencias": "",
        "observaciones": "",
    }


class RegistrarPlaytest666Test(unittest.TestCase):
    def test_gate_exige_pase_completo(self):
        gate = modulo.evaluar_gate(datos_base(True))
        self.assertTrue(gate["viewport_ok"])
        self.assertTrue(gate["dispositivos_ok"])
        self.assertTrue(gate["reduccion_ok"])
        self.assertTrue(gate["escenarios_ok"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["listo_para_cerrar"])

    def test_sin_mando_bloquea(self):
        datos = datos_base(True)
        datos["mando_fisico"] = False
        self.assertFalse(modulo.evaluar_gate(datos)["listo_para_cerrar"])

    def test_sin_reduccion_movimiento_bloquea(self):
        datos = datos_base(True)
        datos["reduccion_movimiento_probada"] = False
        self.assertFalse(modulo.evaluar_gate(datos)["listo_para_cerrar"])

    def test_fixture_no_sustituye_evento_real(self):
        datos = datos_base(True)
        datos["escenarios"]["incidencia"]["evento_real"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["escenarios_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_falta_de_evidencia_bloquea(self):
        datos = datos_base(True)
        datos["escenarios"]["navegacion"]["evidencia"] = ""
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["evidencias_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_viewport_no_canonico_bloquea(self):
        datos = datos_base(True)
        datos["viewport"] = "1280x720"
        self.assertFalse(modulo.evaluar_gate(datos)["listo_para_cerrar"])

    def test_markdown_identifica_build_y_evento_real(self):
        texto = modulo.render_markdown(datos_base(True))
        self.assertIn("build SHA: `abc1234`", texto)
        self.assertIn("mando físico real probado: sí", texto)
        self.assertIn("impresora_atascada", texto)
        self.assertIn("listo para valorar cierre de #666: **SÍ**", texto)


if __name__ == "__main__":
    unittest.main()
