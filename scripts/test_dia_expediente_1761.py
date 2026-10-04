from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"
DIA = (GUION / "dia_app.gd").read_text(encoding="utf-8")
EXPEDIENTE = (GUION / "dia_expediente_app.gd").read_text(encoding="utf-8")
CLIMA = (GUION / "dia_clima_app.gd").read_text(encoding="utf-8")
ESCRITORIO = (GUION / "dia_escritorio_siga_app.gd").read_text(encoding="utf-8")


def funcion(nombre: str, fuente: str) -> str:
    patron = rf"(?ms)^func {re.escape(nombre)}\([^\n]*\).*?(?=^func |\Z)"
    match = re.search(patron, fuente)
    if match is None:
        raise AssertionError(f"no se encontró {nombre}")
    return match.group(0)


def normalizar_accesos(fuente: str) -> str:
    """Tolera el salto de línea que gdformat introduce antes de '. metodo('."""
    return re.sub(r"\s*\.\s*", ".", fuente)


class DiaExpediente1761Test(unittest.TestCase):
    def test_dia_app_delega_presentacion_y_conserva_wrappers(self):
        abrir = normalizar_accesos(funcion("_abrir_expediente", DIA))
        cerrar = normalizar_accesos(funcion("_cerrar_expediente", DIA))
        self.assertLess(len(DIA.splitlines()), 800)
        self.assertIn(
            'const DIA_EXPEDIENTE_APP = preload("res://guion/dia_expediente_app.gd")',
            DIA,
        )
        self.assertIn("DIA_EXPEDIENTE_APP.abrir(", abrir)
        self.assertIn("DIA_EXPEDIENTE_APP.cerrar(", cerrar)
        self.assertIn("func _abrir_expediente() -> void:", DIA)
        self.assertIn("func _cerrar_expediente() -> void:", DIA)

    def test_guardado_bloquea_antes_de_montar_pantalla(self):
        abrir = normalizar_accesos(funcion("_abrir_expediente", DIA))
        pendiente = abrir.index("partida.guardado_pendiente")
        guardar = abrir.index('_guardar_o_avisar("")')
        montar = abrir.index("DIA_EXPEDIENTE_APP.abrir(")
        self.assertLess(pendiente, guardar)
        self.assertLess(guardar, montar)

    def test_helper_posee_solo_ui_transitoria(self):
        for contrato in (
            'load("res://escenas/visor.tscn").instantiate()',
            'volver.text = String(traducir.call("PUESTO_LEVANTARSE"))',
            "volver.pressed.connect(cerrar)",
            "Input.mouse_mode = Input.MOUSE_MODE_VISIBLE",
            "Input.mouse_mode = Input.MOUSE_MODE_CAPTURED",
            'traducir.call("DIA_EN_EL_PUESTO")',
            'nomina.text = ""',
        ):
            self.assertIn(contrato, EXPEDIENTE)
        for prohibido in (
            "Partida.",
            "Jornada.",
            "partida.cargar",
            "_reasignar",
            "_vincular_literatura_partida",
            "EspaciosCatalogo",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, EXPEDIENTE)

    def test_cierre_conserva_recarga_y_prioridad_de_reasignacion(self):
        cerrar = normalizar_accesos(funcion("_cerrar_expediente", DIA))
        orden = (
            'var vuelta_antes := int(jornada.get("vuelta", 1))',
            "DIA_EXPEDIENTE_APP.cerrar(",
            "partida.cargar()",
            "_vincular_literatura_partida()",
            "Jornada.completar(",
            'partida.estado["jornada"] = jornada',
            'if int(jornada.get("vuelta", 1)) != vuelta_antes:',
            "_reasignar()",
            "_caminante.situar(Vector3(-4, 0, 3.2))",
            "_refrescar_rotulos(",
        )
        posiciones = [cerrar.index(token) for token in orden]
        self.assertEqual(posiciones, sorted(posiciones))

    def test_clima_y_escritorio_siguen_usando_wrappers_oficiales(self):
        self.assertIn("super._abrir_expediente()", CLIMA)
        self.assertIn("super._cerrar_expediente()", CLIMA)
        self.assertIn("dia._cerrar_expediente()", ESCRITORIO)
        self.assertIn("dia._pantalla", ESCRITORIO)

    def test_pantalla_sigue_siendo_estado_compartido_del_dia(self):
        self.assertIn("var _pantalla: CanvasLayer", DIA)
        abrir = normalizar_accesos(funcion("_abrir_expediente", DIA))
        cerrar = normalizar_accesos(funcion("_cerrar_expediente", DIA))
        self.assertRegex(abrir, r"_pantalla\s*=\s*\(\s*DIA_EXPEDIENTE_APP\.abrir\(")
        self.assertIn("if _pantalla == null:", cerrar)
        self.assertIn("_pantalla = null", cerrar)


if __name__ == "__main__":
    unittest.main()
