import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


RAIZ = Path(__file__).resolve().parents[1]
EVENTOS = RAIZ / "godot/guion/religion_eventos.gd"
PARTIDA = RAIZ / "godot/guion/partida.gd"
PROMETEO = RAIZ / "godot/guion/prometeo.gd"
FINAL = RAIZ / "godot/guion/final_politico.gd"
PANEL = RAIZ / "godot/guion/final_politico_panel.gd"
TEXTOS_FINAL = RAIZ / "godot/datos/final_politico_textos.json"
PRUEBA_GODOT = "res://pruebas/pruebas_religion_trayectoria_937.gd"


class ReligionTrayectoria937Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.eventos = EVENTOS.read_text(encoding="utf-8")
        cls.partida = PARTIDA.read_text(encoding="utf-8")
        cls.prometeo = PROMETEO.read_text(encoding="utf-8")
        cls.final = FINAL.read_text(encoding="utf-8")
        cls.panel = PANEL.read_text(encoding="utf-8")
        cls.textos_final = json.loads(TEXTOS_FINAL.read_text(encoding="utf-8"))

    def test_historial_es_factual_y_separado_del_registro_activo(self) -> None:
        self.assertIn(
            'CLAVE_HISTORIAL := "historial_trayectorias_religiosas"',
            self.eventos,
        )
        self.assertIn("static func resumen_trayectoria(", self.eventos)
        self.assertIn("static func eventos_de_vuelta(", self.eventos)
        self.assertNotIn('"puntuacion":', self.eventos)
        self.assertNotIn('"identidad":', self.eventos)

    def test_partida_persiste_y_valida_el_historial(self) -> None:
        self.assertIn("ReligionEventos.CLAVE_HISTORIAL: []", self.partida)
        self.assertIn("ReligionEventos.validar_historial_trayectorias", self.partida)

    def test_reset_sella_antes_de_limpiar_la_vuelta(self) -> None:
        ideologia = 'archivar_trayectoria_ideologica(estado, "reinicio_vuelta")'
        religion = 'ReligionEventos.archivar_trayectoria(estado, "reinicio_vuelta")'
        self.assertIn(religion, self.prometeo)
        self.assertLess(self.prometeo.index(ideologia), self.prometeo.index(religion))

    def test_final_consume_y_sella_la_misma_trayectoria(self) -> None:
        self.assertIn("ReligionEventos.resumen_trayectoria(estado)", self.final)
        self.assertIn("ReligionTrayectoria.resumir(", self.final)
        self.assertIn(
            'ReligionEventos.archivar_trayectoria(estado, "final_narrativo")',
            self.final,
        )

    def test_panel_muestra_hechos_sin_crear_estado(self) -> None:
        self.assertIn("_montar_religion(caja)", self.panel)
        self.assertIn("_texto_hecho_religion(", self.panel)
        self.assertNotIn("ReligionEventos.registrar(", self.panel)
        for clave in (
            "religion_titulo",
            "religion_hecho_formato",
            "religion_mas",
            "religion_canales",
            "religion_declaraciones",
        ):
            self.assertIn(clave, self.textos_final)

    def test_regresion_runtime(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="religion-937-") as temporal:
            entorno = os.environ.copy()
            for variable, carpeta in (
                ("XDG_DATA_HOME", "datos"),
                ("XDG_CONFIG_HOME", "config"),
                ("XDG_CACHE_HOME", "cache"),
            ):
                entorno[variable] = str(Path(temporal) / carpeta)

            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--path",
                    str(RAIZ / "godot"),
                    "--script",
                    PRUEBA_GODOT,
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=45,
                check=False,
            )

        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")


if __name__ == "__main__":
    unittest.main()
