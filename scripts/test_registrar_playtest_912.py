import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("registrar_playtest_912.py")
spec = importlib.util.spec_from_file_location("registrar_playtest_912", SCRIPT)
modulo = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(modulo)


def datos_base(valor: bool = True) -> dict[str, object]:
    encuentros = {}
    for clave, _titulo in modulo.ENCUENTROS:
        registro = {
            nombre: 1 for nombre, _descripcion in modulo.METRICAS_ENTERAS
        }
        for nombre, _descripcion in modulo.CHECKS_ENCUENTRO:
            registro[nombre] = valor
        if clave != "base":
            registro["ritual_cambio_decision"] = valor
        registro["evidencia"] = f"docs/playtests/912-{clave}.png" if valor else ""
        registro["incidencias"] = ""
        encuentros[clave] = registro

    return {
        "fecha": "2026-09-25T19:15:00+02:00",
        "tester": "tester",
        "plataforma": "Linux",
        "build_sha": "abc1234",
        "viewport": "1920×1080",
        "encuentros": encuentros,
        "matriz_teclado_completa": valor,
        "muestra_mando_fisico": valor,
        "mando_modelo": "mando USB",
        "reduccion_movimiento_equivalente": valor,
        "sin_ritual_dominante_o_inutil": valor,
        "acciones_diferenciadas": valor,
        "observaciones": "",
    }


class RegistrarPlaytest912Test(unittest.TestCase):
    def test_matriz_canonica_tiene_base_y_seis_rituales(self):
        self.assertEqual(len(modulo.ENCUENTROS), 7)
        self.assertEqual(modulo.ENCUENTROS[0][0], "base")
        self.assertEqual(
            {clave for clave, _titulo in modulo.ENCUENTROS[1:]},
            {
                "luna_minotauro",
                "justicia_duat",
                "fuerza_aquiles",
                "sol_maui",
                "colgado_anansi",
                "muerte_hidra",
            },
        )

    def test_gate_solo_cumple_con_registro_humano_completo(self):
        gate = modulo.evaluar_registro(datos_base(True))
        self.assertTrue(gate["viewport_ok"])
        self.assertTrue(gate["matriz_completa"])
        self.assertTrue(gate["evidencias_ok"])
        self.assertTrue(gate["checks_ok"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_no_hace_balance_automatico_con_metricas(self):
        datos = datos_base(True)
        datos["encuentros"]["sol_maui"]["duracion_segundos"] = 999
        datos["encuentros"]["muerte_hidra"]["determinacion_perdida_rival"] = 999
        gate = modulo.evaluar_registro(datos)
        self.assertTrue(gate["matriz_completa"])
        self.assertTrue(gate["listo_para_valorar_cierre"])

    def test_falta_de_evidencia_bloquea_el_gate(self):
        datos = datos_base(True)
        datos["encuentros"]["justicia_duat"]["evidencia"] = ""
        gate = modulo.evaluar_registro(datos)
        self.assertFalse(gate["evidencias_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_mando_y_reduccion_de_movimiento_son_gates_explicitos(self):
        datos = datos_base(True)
        datos["muestra_mando_fisico"] = False
        datos["reduccion_movimiento_equivalente"] = False
        gate = modulo.evaluar_registro(datos)
        self.assertFalse(gate["mando_ok"])
        self.assertFalse(gate["reduccion_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_un_fallo_de_legibilidad_no_se_oculta_en_las_metricas(self):
        datos = datos_base(True)
        datos["encuentros"]["base"]["telegraph_legible"] = False
        gate = modulo.evaluar_registro(datos)
        self.assertFalse(gate["checks_ok"])
        self.assertFalse(gate["listo_para_valorar_cierre"])

    def test_markdown_traza_build_matriz_y_limite_del_script(self):
        texto = modulo.render_markdown(datos_base(True))
        self.assertIn("build SHA: `abc1234`", texto)
        self.assertIn("Combate base · sin ritual", texto)
        self.assertIn("Muerte + Hidra · Retorno de la Hidra", texto)
        self.assertIn("no declara un ritual mejor que otro", texto)
        self.assertIn("listo para valorar cierre de #912:", texto)
        self.assertIn("**SÍ**", texto)


if __name__ == "__main__":
    unittest.main()
