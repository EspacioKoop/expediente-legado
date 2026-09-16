import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SMOKE = ROOT / "godot" / "pruebas" / "pruebas_gilgamesh_recorrido.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class GilgameshRecorridoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.smoke = SMOKE.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_smoke_entra_por_el_recorrido_real(self):
        self.assertIn('const DIA := preload("res://escenas/dia.tscn")', self.smoke)
        self.assertIn('dia._entrar_en("casa")', self.smoke)
        self.assertIn('get_node_or_null("GilgameshVigiliaCasa")', self.smoke)
        self.assertIn("libro.interactuar(actor)", self.smoke)
        self.assertIn("Jornada.dormir(dia.jornada)", self.smoke)
        self.assertIn("dia._aplicar_politica_sueno()", self.smoke)
        self.assertIn('dia._entrar_en("sueño")', self.smoke)
        self.assertIn('get_node_or_null("SuenoGilgameshNoche")', self.smoke)
        self.assertNotIn("SuenoGilgamesh.registrar_semilla", self.smoke)

    def test_smoke_resuelve_por_interactuables_y_no_por_api_directa(self):
        self.assertIn('"Interactuar_fragmento_puerta"', self.smoke)
        self.assertIn('"Interactuar_ancla_ola"', self.smoke)
        self.assertIn('"Interactuar_ancla_puerta"', self.smoke)
        self.assertIn("fragmento.interactuar(actor)", self.smoke)
        self.assertIn("ancla.interactuar(actor)", self.smoke)
        self.assertIn('interaccion.call("fragmento_seleccionado")', self.smoke)
        self.assertNotIn("colocar_fragmento(", self.smoke)

    def test_smoke_verifica_transformacion_y_camara(self):
        self.assertIn('get_node_or_null("CamaraStandalone") == null', self.smoke)
        self.assertIn('"CiudadImposible/MurallaArchivoTecho"', self.smoke)
        self.assertIn('"CiudadImposible/PuertaBloqueada"', self.smoke)
        self.assertIn('"CiudadImposible/RutaFinal"', self.smoke)
        self.assertIn("sueno.resuelto()", self.smoke)

    def test_dia_sigue_montando_controller_nocturno(self):
        self.assertIn('path="res://guion/dia_gilgamesh_sueno_app.gd"', self.dia)
        self.assertIn(
            '[node name="GilgameshSuenoController" type="Node" parent="."]',
            self.dia,
        )

    @unittest.skipUnless(
        shutil.which(os.environ.get("GODOT_BIN", "godot4")),
        "Godot no está disponible en PATH",
    )
    def test_smoke_godot_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="gilgamesh-recorrido-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    "res://pruebas/pruebas_gilgamesh_recorrido.gd",
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=120,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
