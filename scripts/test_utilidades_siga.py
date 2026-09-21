import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
BLOC = ROOT / "godot" / "guion" / "bloc_notas_siga.gd"
CALCULADORA = ROOT / "godot" / "guion" / "calculadora_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"


class UtilidadesSigaTest(unittest.TestCase):
    def test_bloc_es_app_persistible_y_aislada_por_partida(self) -> None:
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn('"bloc-notas", "Bloc de notas"', fuente)
        self.assertIn("_bloc_notas_app.persistir_estado = true", fuente)
        self.assertIn('obtener_estado_local("texto_por_partida", {})', fuente)
        self.assertIn('establecer_estado_local("texto_por_partida", por_partida)', fuente)
        self.assertIn("_clave_partida(dia)", fuente)
        self.assertIn("bloc.contenido_cambiado.connect(_registrar_texto_bloc)", fuente)

    def test_calculadora_es_app_real_sin_estado_persistido(self) -> None:
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn('"calculadora", "Calculadora"', fuente)
        self.assertIn('Callable(self, "_crear_calculadora")', fuente)
        self.assertNotIn("_calculadora_app.persistir_estado = true", fuente)

    def test_bloc_no_escribe_en_el_host(self) -> None:
        fuente = BLOC.read_text(encoding="utf-8")
        self.assertIn("class_name BlocNotasSiga", fuente)
        self.assertIn("TextEdit.new()", fuente)
        self.assertIn("signal contenido_cambiado", fuente)
        for api in ("FileAccess", "DirAccess", "OS.", "execute("):
            self.assertNotIn(api, fuente)

    def test_calculadora_limita_la_superficie_de_ejecucion(self) -> None:
        fuente = CALCULADORA.read_text(encoding="utf-8")
        self.assertIn("class_name CalculadoraSiga", fuente)
        self.assertIn("CARACTERES_PERMITIDOS", fuente)
        self.assertIn("Expression.new()", fuente)
        self.assertIn("_entrada_permitida", fuente)
        for api in ("FileAccess", "DirAccess", "OS.", "JavaScriptBridge", "Shell"):
            # Límite de palabra: «CARACTERES_PERMITIDOS.contains» no es «OS.».
            self.assertIsNone(re.search(rf"\b{re.escape(api)}", fuente), api)


    def test_calculadora_tiene_identidad_visual_y_teclado_propios(self) -> None:
        fuente = CALCULADORA.read_text(encoding="utf-8")
        self.assertIn("PanelContainer.new()", fuente)
        self.assertIn("GridContainer.new()", fuente)
        self.assertIn("teclado.columns = 4", fuente)
        self.assertIn("_crear_tecla", fuente)
        self.assertIn("add_theme_stylebox_override", fuente)
        self.assertIn("add_theme_color_override", fuente)
        self.assertIn('"Pantalla"', fuente)
        self.assertIn('"Teclado"', fuente)

    def test_utilidades_ejecutables_en_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_utilidades_siga.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("12 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
