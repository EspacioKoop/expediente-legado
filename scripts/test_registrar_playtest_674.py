import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("registrar_playtest_674.py")
spec = importlib.util.spec_from_file_location("registrar_playtest_674", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


def datos_base(valor: bool = True) -> dict[str, object]:
    escenarios = {}
    for clave, _titulo, checks in modulo.ESCENARIOS:
        registro = {nombre: valor for nombre, _descripcion in checks}
        registro["captura"] = f"docs/playtests/{clave}.png" if valor else ""
        registro["notas"] = ""
        escenarios[clave] = registro

    return {
        "fecha": "2026-09-28T22:30:00+02:00",
        "tester": "tester",
        "plataforma": "Linux",
        "build_sha": "abc1234",
        "viewport": "1920×1080",
        "teclado_real": valor,
        "mando_fisico": valor,
        "mando_modelo": "mando USB",
        "ignorar_no_bloquea": valor,
        "escenarios": escenarios,
        "incidencias": "",
        "observaciones": "",
    }


class RegistrarPlaytest674Test(unittest.TestCase):
    def test_gate_cumple_solo_con_pase_humano_completo(self):
        gate = modulo.evaluar_gate(datos_base(True))
        self.assertTrue(gate["viewport_ok"])
        self.assertTrue(gate["dispositivos_ok"])
        self.assertTrue(gate["escenarios_ok"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["opcionalidad_ok"])
        self.assertTrue(gate["listo_para_cerrar"])

    def test_viewport_no_canonico_bloquea_el_cierre(self):
        datos = datos_base(True)
        datos["viewport"] = "1280x720"
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["viewport_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_sin_mando_fisico_bloquea_el_cierre(self):
        datos = datos_base(True)
        datos["mando_fisico"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["dispositivos_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_fallo_de_legibilidad_bloquea_el_cierre(self):
        datos = datos_base(True)
        datos["escenarios"]["visor"]["texto_legible"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["escenarios_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_falta_de_evidencia_bloquea_el_cierre(self):
        datos = datos_base(True)
        datos["escenarios"]["casa"]["captura"] = ""
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["evidencias_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_publicaciones_obligatorias_bloquean_el_cierre(self):
        datos = datos_base(True)
        datos["ignorar_no_bloquea"] = False
        gate = modulo.evaluar_gate(datos)
        self.assertFalse(gate["opcionalidad_ok"])
        self.assertFalse(gate["listo_para_cerrar"])

    def test_markdown_traza_build_dispositivos_y_escenarios(self):
        texto = modulo.render_markdown(datos_base(True))
        self.assertIn("build SHA: `abc1234`", texto)
        self.assertIn("viewport: `1920×1080`", texto)
        self.assertIn("teclado real probado: sí", texto)
        self.assertIn("mando físico real probado: sí", texto)
        for _clave, titulo, _checks in modulo.ESCENARIOS:
            self.assertIn(titulo, texto)
        self.assertIn("listo para valorar cierre de #674: **SÍ**", texto)


if __name__ == "__main__":
    unittest.main()
