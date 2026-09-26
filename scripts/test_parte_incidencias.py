import json
import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
NUCLEO = ROOT / "godot" / "guion" / "parte_incidencias.gd"
APP = ROOT / "godot" / "guion" / "parte_incidencias_app.gd"
REPORTADOR = ROOT / "godot" / "guion" / "reportador_f9.gd"
PROJECT = ROOT / "godot" / "project.godot"
CONFIG = ROOT / "godot" / "datos" / "incidencias.json"
EXPORT = ROOT / "dist" / "exportar-godot-alpha.sh"
WORKFLOW = ROOT / ".github" / "workflows" / "alpha-playtest.yml"
WORKER = ROOT / "infra" / "feedback-worker" / "worker.js"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class ParteIncidenciasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.nucleo = NUCLEO.read_text(encoding="utf-8")
        cls.app = APP.read_text(encoding="utf-8")
        cls.reportador = REPORTADOR.read_text(encoding="utf-8")
        cls.project = PROJECT.read_text(encoding="utf-8")
        cls.config = json.loads(CONFIG.read_text(encoding="utf-8"))
        cls.export = EXPORT.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.worker = WORKER.read_text(encoding="utf-8")

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
        self.assertGreaterEqual(int(resumen.group(1)), 24, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_f9_es_global_y_preserva_estado_previo(self):
        self.assertIn('ReportadorF9="*res://guion/reportador_f9.gd"', self.project)
        self.assertIn("KEY_F9", self.reportador)
        self.assertIn("func _input(evento: InputEvent)", self.reportador)
        self.assertIn("_pausa_previa = get_tree().paused", self.reportador)
        self.assertIn("get_tree().paused = _pausa_previa", self.reportador)
        self.assertIn("_mouse_previo = Input.mouse_mode", self.reportador)
        self.assertIn("Input.mouse_mode = _mouse_previo", self.reportador)
        self.assertIn("_foco_previo = get_viewport().gui_get_focus_owner()", self.reportador)
        self.assertIn("_app.abrir(PreferenciasSiga.cargar(), true)", self.reportador)

    def test_endpoint_esta_fuera_del_codigo_y_se_inyecta_al_exportar(self):
        self.assertEqual(self.config["feedback_url"], "")
        self.assertIn("SIGA98_FEEDBACK_URL", self.export)
        self.assertIn("datos/incidencias.json", self.export)
        self.assertIn('url.startswith(("https://", "http://"))', self.export)
        self.assertIn("vars.SIGA98_FEEDBACK_URL", self.workflow)
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
            "partida.estado",
        ):
            self.assertNotIn(prohibido, self.nucleo + self.app)
        self.assertIn("filtrar_diagnostico", self.nucleo)
        self.assertIn('ruta.begins_with("res://")', self.nucleo)

    def test_build_usa_sha_del_paquete_si_existe(self):
        self.assertIn('"BUILD-INFO.txt"', self.nucleo)
        self.assertIn('"build_sha="', self.nucleo)
        self.assertIn("OS.get_executable_path()", self.nucleo)
        self.assertIn("build_actual()", self.nucleo)

    def test_diagnostico_f9_es_visible_y_desmarcable(self):
        self.assertIn("_diagnostico.button_pressed = diagnostico_por_defecto", self.app)
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

    def test_envio_es_post_json_y_no_portapapeles(self):
        self.assertIn("HTTPRequest.new()", self.app)
        self.assertIn("HTTPClient.METHOD_POST", self.app)
        self.assertIn('"Content-Type: application/json"', self.app)
        self.assertIn("JSON.stringify(payload)", self.app)
        self.assertNotIn("clipboard_set", self.app)
        self.assertNotIn("api.github.com", self.app)
        self.assertNotIn("Authorization", self.app)

    def test_fallback_abre_issue_prerellenado(self):
        self.assertEqual(
            self.config["fallback_issue_url"],
            "https://github.com/EspacioKoop/expediente-legado/issues/new",
        )
        self.assertIn("url_issue_preparado", self.nucleo)
        self.assertIn("OS.shell_open(url)", self.app)
        self.assertIn("guardar_local", self.app)

    def test_gateway_guarda_secretos_solo_en_servidor(self):
        self.assertIn("GITHUB_TOKEN", self.worker)
        self.assertIn("https://api.github.com/repos/", self.worker)
        self.assertIn("/issues", self.worker)
        self.assertIn("RESEND_API_KEY", self.worker)
        self.assertIn("https://api.resend.com/emails", self.worker)
        cliente = self.nucleo + self.app + self.reportador
        for secreto in ("GITHUB_TOKEN", "RESEND_API_KEY", "REPORT_EMAIL_TO"):
            self.assertNotIn(secreto, cliente)

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
