import json
import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
NUCLEO = ROOT / "godot" / "guion" / "parte_incidencias.gd"
APP = ROOT / "godot" / "guion" / "parte_incidencias_app.gd"
MENU = ROOT / "godot" / "guion" / "menu_global.gd"
CONFIG = ROOT / "godot" / "datos" / "incidencias.json"
EXPORT = ROOT / "dist" / "exportar-godot-alpha.sh"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class ParteIncidenciasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.nucleo = NUCLEO.read_text(encoding="utf-8")
        cls.app = APP.read_text(encoding="utf-8")
        cls.menu = MENU.read_text(encoding="utf-8")
        cls.config = json.loads(CONFIG.read_text(encoding="utf-8"))
        cls.export = EXPORT.read_text(encoding="utf-8")

    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_parte_incidencias.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 16, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_endpoint_esta_fuera_del_codigo_y_se_inyecta_al_exportar(self):
        self.assertEqual(self.config["feedback_url"], "")
        self.assertIn("SIGA98_FEEDBACK_URL", self.export)
        self.assertIn("datos/incidencias.json", self.export)
        self.assertIn('url.startswith(("https://", "http://"))', self.export)
        self.assertNotIn("SIGA98_FEEDBACK_URL", self.nucleo)
        self.assertNotIn("SIGA98_FEEDBACK_URL", self.app)

    def test_diagnostico_es_lista_blanca_y_no_inspecciona_entorno(self):
        for clave in (
            '"build"',
            '"godot"',
            '"plataforma"',
            '"escena"',
            '"renderer"',
            '"reduccion_movimiento"',
        ):
            self.assertIn(clave, self.nucleo)
        for prohibido in (
            "OS.get_environment",
            "get_user_data_dir",
            "HTTPClient",
            "HTTPRequest",
            "partida.estado",
        ):
            self.assertNotIn(prohibido, self.nucleo + self.app)
        self.assertIn("filtrar_diagnostico", self.nucleo)
        self.assertIn('ruta.begins_with("res://")', self.nucleo)

    def test_diagnostico_requiere_consentimiento_y_muestra_previa(self):
        self.assertIn("_diagnostico.button_pressed", self.app)
        self.assertIn("_diagnostico_previa.visible = activo", self.app)
        self.assertIn("formatear_diagnostico", self.app)
        self.assertEqual(
            self.config["textos"]["diagnostico"],
            "Adjuntar diagnóstico técnico filtrado",
        )

    def test_pantalla_no_hardcodea_texto_visible(self):
        patron = re.compile(
            r"\.(?:text|placeholder_text|tooltip_text)\s*=\s*\"[^\"]+\""
        )
        self.assertEqual(patron.findall(self.app), [])
        self.assertIn("texto_interfaz", self.nucleo)
        self.assertIn('"textos"', CONFIG.read_text(encoding="utf-8"))

    def test_transporte_copia_antes_de_abrir_y_tiene_fallback_local(self):
        copiar = "DisplayServer.clipboard_set(parte)"
        abrir = "OS.shell_open(url)"
        self.assertIn(copiar, self.app)
        self.assertIn(abrir, self.app)
        self.assertLess(self.app.index(copiar), self.app.index(abrir))
        self.assertIn("guardar_local", self.app)
        self.assertIn("user://parte-incidencias-", self.nucleo)

    def test_menu_global_expone_el_parte_y_restaura_foco(self):
        self.assertIn("ParteIncidenciasApp.new()", self.menu)
        self.assertIn("ParteIncidencias.ETIQUETA", self.menu)
        self.assertIn("_mostrar_incidencias", self.menu)
        self.assertIn("_incidencias.grab_focus()", self.menu)
        self.assertIn("_volver_de_incidencias", self.menu)

    def test_formulario_usa_controles_navegables_estandar(self):
        for control in (
            "OptionButton.new()",
            "LineEdit.new()",
            "TextEdit.new()",
            "CheckButton.new()",
            "Button.new()",
        ):
            self.assertIn(control, self.app)
        self.assertIn("_categoria.grab_focus()", self.app)


if __name__ == "__main__":
    unittest.main()
