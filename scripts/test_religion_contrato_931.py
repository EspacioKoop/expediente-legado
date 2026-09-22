import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


RAIZ = Path(__file__).resolve().parents[1]
EVENTOS = RAIZ / "godot/guion/religion_eventos.gd"
PARTIDA = RAIZ / "godot/guion/partida.gd"
ROMS = RAIZ / "godot/guion/dia_religion_roms_app.gd"
ROM_OBSERVER = RAIZ / "godot/guion/religion_rom_vigilia.gd"
MUNDO = RAIZ / "godot/guion/religion_mundo_934.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_religion_contrato_931.gd"


class ReligionContrato931Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.eventos = EVENTOS.read_text(encoding="utf-8")
        cls.partida = PARTIDA.read_text(encoding="utf-8")
        cls.roms = ROMS.read_text(encoding="utf-8")
        cls.rom_observer = ROM_OBSERVER.read_text(encoding="utf-8")
        cls.mundo = MUNDO.read_text(encoding="utf-8")

    def test_partida_es_fuente_de_verdad_persistente(self) -> None:
        self.assertIn("ReligionEventos.CLAVE_ESTADO: ReligionEventos.nuevo()", self.partida)
        self.assertIn("ReligionEventos.validar", self.partida)
        self.assertIn("ReligionEventos.asegurar_en_estado(fusionado)", self.partida)

    def test_roms_y_mundo_comparten_el_contrato(self) -> None:
        self.assertIn(
            "ReligionEventos.asegurar_en_estado(dia.partida.estado)",
            self.roms,
        )
        self.assertIn("ReligionEventos.CANAL_EXPOSICION", self.rom_observer)
        self.assertIn("ReligionEventos.CANAL_EXPOSICION", self.mundo)
        self.assertIn("ReligionEventos.CANAL_PRACTICA", self.mundo)
        self.assertIn('"procedencia": "rom:handshake:c100"', self.rom_observer)
        self.assertIn('"procedencia": "mundo:interaccion:examinar"', self.mundo)

    def test_declaraciones_no_son_un_score_global(self) -> None:
        for declaracion in (
            "DECLARACION_AFIRMACION",
            "DECLARACION_DUDA",
            "DECLARACION_NO_ADSCRIPCION",
            "DECLARACION_CAMBIO",
        ):
            self.assertIn(declaracion, self.eventos)
        self.assertIn("ultima_declaracion", self.eventos)
        self.assertIn("vinculos_por_actor", self.eventos)
        self.assertNotIn('"fe":', self.eventos)
        self.assertNotIn('"religiosidad":', self.eventos)

    def test_regresion_runtime(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="religion-931-") as temporal:
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
