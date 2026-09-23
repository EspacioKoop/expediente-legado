from pathlib import Path
import os
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
LIBRO = ROOT / "godot" / "interactables" / "libros" / "libro_lectura_significativa.gd"
BIBLIOTECA = ROOT / "godot" / "espacios" / "biblioteca" / "biblioteca.tscn"
RITUAL = ROOT / "godot" / "rituales" / "literarios" / "ritual_cita.gd"
TEST_GODOT = "res://pruebas/pruebas_biblioteca_literaria_1181.gd"


class BibliotecaLiteraria1181Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.libro = LIBRO.read_text(encoding="utf-8")
        cls.biblioteca = BIBLIOTECA.read_text(encoding="utf-8")
        cls.ritual = RITUAL.read_text(encoding="utf-8")

    def test_lectura_fisica_usa_contrato_nuevo(self) -> None:
        self.assertIn("registrar_lectura_significativa", self.libro)
        self.assertIn("pasos_para_completar", self.libro)
        self.assertNotIn("conocer_obra(", self.libro)
        self.assertNotIn("CANAL_POSESION", self.libro)
        self.assertNotIn("SIGA", self.libro)

    def test_biblioteca_expone_obra_y_mesa_ritual(self) -> None:
        self.assertIn("LibroVidaEsSueno", self.biblioteca)
        self.assertIn('obra_id = "vida_es_sueno_1635"', self.biblioteca)
        self.assertIn("MesaRitual", self.biblioteca)
        self.assertIn("RitualCita", self.biblioteca)
        self.assertIn("StaticBody3D", self.biblioteca)
        self.assertIn("Label3D", self.biblioteca)

    def test_ui_ritual_consume_contrato_contextual(self) -> None:
        self.assertIn("ejecutar_ritual_cita", self.ritual)
        self.assertIn("CANAL_INSIGHT", self.ritual)
        self.assertIn("agregar_momentum", self.ritual)
        self.assertNotIn("momentum_actual -=", self.ritual)
        self.assertNotIn("res://datos/literatura/obras.json", self.ritual)

    def test_godot_vertical(self) -> None:
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="biblioteca-1181-") as tmp:
            env = os.environ.copy()
            env["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                env[key] = str(Path(tmp) / key)
            result = subprocess.run(
                [
                    engine,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    TEST_GODOT,
                ],
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=240,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("0 fallos", result.stdout)


if __name__ == "__main__":
    unittest.main()
