import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "godot/guion/auditorias_siga.gd").read_text(encoding="utf-8")
CREADOR = (ROOT / "godot/guion/creador_personaje_app.gd").read_text(encoding="utf-8")
ADAPTADOR = (ROOT / "godot/guion/dia_escritorio_siga_app.gd").read_text(encoding="utf-8")
TEXTOS = (ROOT / "godot/datos/textos.csv").read_text(encoding="utf-8")
PRUEBA_GODOT = "res://pruebas/pruebas_auditorias_siga.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class AuditoriasSigaTests(unittest.TestCase):
    def test_superficie_reutilizable_separa_seleccion_y_consulta(self):
        self.assertIn("class_name AuditoriasSiga", UI)
        self.assertIn("func configurar_estado(estado_partida: Dictionary, editable: bool = false)", UI)
        self.assertIn("func seleccion() -> Array:", UI)
        self.assertIn("CheckBox.new()", UI)
        self.assertIn("check.disabled = not _editable", UI)
        self.assertIn("check.set_pressed_no_signal", UI)

    def test_la_ui_no_persiste_ni_resuelve_reglas(self):
        for prohibido in (
            "partida.guardar(",
            "Auditorias.fallar(",
            "Auditorias.completar(",
            "Jornada.",
            "Sellos.",
            "Steam",
        ):
            self.assertNotIn(prohibido, UI)

    def test_alta_inicial_es_el_owner_de_la_seleccion(self):
        guardar = CREADOR.split("func _guardar() -> void:", 1)[1].split(
            "func _volver() -> void:", 1
        )[0]
        self.assertIn("var _auditorias: AuditoriasSiga", CREADOR)
        self.assertIn("_auditorias.configurar_estado(_partida.estado, _alta_pendiente)", CREADOR)
        self.assertIn("if _alta_pendiente and _auditorias != null:", guardar)
        self.assertIn(
            "Auditorias.resolver_seleccion(_partida.estado, _auditorias.seleccion())",
            guardar,
        )
        self.assertLess(
            guardar.index("Auditorias.resolver_seleccion"),
            guardar.index("_partida.guardar()"),
        )

    def test_siga_registra_una_app_de_consulta(self):
        self.assertIn("var _auditorias_app: EscritorioSigaApp", ADAPTADOR)
        self.assertIn('"auditorias"', ADAPTADOR)
        self.assertIn('Callable(self, "_crear_auditorias")', ADAPTADOR)
        self.assertIn("AuditoriasSiga.new()", ADAPTADOR)
        self.assertIn("auditorias.configurar_estado(partida_actual.estado, false)", ADAPTADOR)

    def test_textos_viven_en_catalogo(self):
        for clave in (
            "AUDITORIAS_APP_TITULO,",
            "AUDITORIAS_CABECERA,",
            "AUDITORIAS_AYUDA_SELECCION,",
            "AUDITORIAS_AYUDA_CONSULTA,",
            "AUDITORIAS_ACCION_SOBRANTE,",
            "AUDITORIAS_ACCION_SOBRANTE_DESC,",
            "AUDITORIAS_ESTADO_ACTIVA,",
            "AUDITORIAS_ESTADO_FALLIDA,",
            "AUDITORIAS_ESTADO_COMPLETADA,",
            "AUDITORIAS_ESTADO_INACTIVA,",
        ):
            self.assertIn(clave, TEXTOS)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 14, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
