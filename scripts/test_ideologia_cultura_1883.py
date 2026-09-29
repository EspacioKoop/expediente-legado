import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "ideologia_cultura_cotidiana_1883.gd"
RONDA = ROOT / "godot" / "guion" / "dia_ronda_cierre_app.gd"
RONDA_3D = ROOT / "godot" / "guion" / "ronda_cierre_3d.gd"
CORREO = ROOT / "godot" / "guion" / "correo_postal.gd"
CORREO_APP = ROOT / "godot" / "guion" / "dia_correo_postal_app.gd"
PRUEBA = "res://pruebas/pruebas_ideologia_cultura_1883.gd"


class IdeologiaCultura1883Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.modelo = MODELO.read_text(encoding="utf-8")
        cls.ronda = RONDA.read_text(encoding="utf-8")
        cls.ronda_3d = RONDA_3D.read_text(encoding="utf-8")
        cls.correo = CORREO.read_text(encoding="utf-8")
        cls.correo_app = CORREO_APP.read_text(encoding="utf-8")

    def test_dos_superficies_comparten_hecho_sin_estado_nuevo(self):
        self.assertIn('EVENTO_BASE := "turnos-atencion-planta4"', self.modelo)
        self.assertIn('SUPERFICIE_CIRCULAR := "circular_oficina"', self.modelo)
        self.assertIn('SUPERFICIE_POSTAL := "aviso_postal"', self.modelo)
        self.assertEqual(self.modelo.count('"evento_base": EVENTO_BASE'), 2)
        self.assertIn("Prometeo.registrar_exposicion_ideologica(", self.modelo)
        self.assertNotIn("registrar_eleccion_ideologica(", self.modelo)
        self.assertNotIn('["elecciones_ideologicas_run"] =', self.modelo)

    def test_tablon_registra_solo_al_completar_interaccion(self):
        self.assertIn('if id_punto == "comprobar_tablon":', self.ronda)
        self.assertIn("_registrar_exposicion_tablon(dia)", self.ronda)
        self.assertIn("IdeologiaCulturaCotidiana1883.registrar_exposicion(", self.ronda)
        self.assertIn('punto.set_meta("ideologia_superficie_id"', self.ronda_3d)
        self.assertIn('punto.set_meta("evento_base"', self.ronda_3d)
        self.assertNotIn("registrar_eleccion_ideologica(", self.ronda)

    def test_correo_registra_antes_del_guardado_y_solo_si_lleva_metadato(self):
        self.assertIn("IdeologiaCulturaCotidiana1883.pieza_postal()", self.correo)
        self.assertIn('"id": "aviso_horario_planta4"', self.modelo)
        registro = self.correo_app.index("_registrar_exposicion_si_toca(dia, resultado)")
        guardado = self.correo_app.index('dia._guardar_o_avisar("")')
        self.assertLess(registro, guardado)
        self.assertIn('get("ideologia_superficie_id", "")', self.correo_app)
        self.assertIn("IdeologiaCulturaCotidiana1883.registrar_exposicion(", self.correo_app)
        self.assertNotIn("registrar_eleccion_ideologica(", self.correo_app)

    def test_smoke_godot(self):
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="ideologia-1883-") as temporal:
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
                    str(ROOT / "godot"),
                    "--script",
                    PRUEBA,
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=30,
                check=False,
            )

        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"issue_1883: \d+ pasadas, 0 fallos")
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
