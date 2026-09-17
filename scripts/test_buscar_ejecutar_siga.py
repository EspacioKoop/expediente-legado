import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SUPERFICIE = ROOT / "godot" / "guion" / "buscar_ejecutar_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"


class BuscarEjecutarSigaTest(unittest.TestCase):
    def test_busqueda_reutiliza_modelos_de_visibilidad(self) -> None:
        fuente = SUPERFICIE.read_text(encoding="utf-8")
        self.assertIn("ExploradorSigaModelo.new()", fuente)
        self.assertIn("explorador.puede_acceder(entrada)", fuente)
        self.assertIn("Web98Indice.new()", fuente)
        self.assertIn("web.buscar(consulta)", fuente)
        self.assertIn("web.resolver_url(limpio)", fuente)

    def test_ejecutar_es_catalogo_cerrado_y_no_shell(self) -> None:
        fuente = SUPERFICIE.read_text(encoding="utf-8")
        self.assertIn("func resolver_comando", fuente)
        self.assertIn('normalizado in ["help", "ayuda", "?"]', fuente)
        self.assertIn('"Comando no reconocido', fuente)
        for api in ("FileAccess", "DirAccess", "OS.", "JavaScriptBridge", "create_process"):
            self.assertNotIn(api, fuente)

    def test_adaptador_registra_ambas_superficies(self) -> None:
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn('"buscar", "Buscar"', fuente)
        self.assertIn('Callable(self, "_crear_buscar")', fuente)
        self.assertIn('"ejecutar", "Ejecutar…"', fuente)
        self.assertIn('Callable(self, "_crear_ejecutar")', fuente)
        self.assertIn("abrir_aplicacion.connect(_abrir_aplicacion_lanzador)", fuente)
        self.assertIn("abrir_ruta.connect(_abrir_ruta_lanzador)", fuente)
        self.assertIn("abrir_url.connect(_abrir_url_lanzador)", fuente)

    def test_superficies_ejecutables_en_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_buscar_ejecutar_siga.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("11 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
