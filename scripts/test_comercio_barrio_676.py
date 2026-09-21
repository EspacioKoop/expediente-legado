"""Superficies físicas del comercio de barrio (#676)."""

from pathlib import Path
import os
import re
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"
ARTE = ROOT / "godot/arte/comercio_barrio"
PRUEBA = "res://pruebas/pruebas_comercio_barrio_676.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class ComercioBarrio676FisicoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.helper = (GUION / "comercio_barrio_3d.gd").read_text(encoding="utf-8")
        cls.calle = (GUION / "dia_calle_app.gd").read_text(encoding="utf-8")

    def test_dia_monta_las_dos_superficies_sin_interiores_nuevos(self):
        self.assertIn("ComercioBarrio3D.montar(self, calle)", self.calle)
        self.assertIn('"QuioscoAvenida"', self.helper)
        self.assertIn('"ElTrastero"', self.helper)
        self.assertNotIn("Espacio3D.construir", self.helper)

    def test_no_duplica_catalogo_ni_economia(self):
        self.assertRegex(self.helper, r"ComercioBarrio\s*\.\s*listar\s*\(")
        self.assertRegex(self.helper, r"ComercioBarrio\s*\.\s*comprar\s*\(")
        self.assertRegex(self.helper, r"ComercioBarrio\s*\.\s*vender\s*\(")
        self.assertNotIn("Jornada.gastar", self.helper)
        self.assertNotIn("const CATALOGO", self.helper)
        self.assertNotIn("precio_reventa", self.helper)

    def test_reutiliza_publicaciones_y_destino_casa(self):
        self.assertIn("PublicacionFisica3D.montar", self.helper)
        self.assertIn('Inventario.HOME_STORAGE', (
            ROOT / "godot/pruebas/pruebas_comercio_barrio_676.gd"
        ).read_text(encoding="utf-8"))

    def test_reventa_fisica_usa_solo_carried(self):
        self.assertIn('"BandejaReventa"', self.helper)
        self.assertIn("Inventario.CARRIED", self.helper)
        self.assertIn('venta.set_meta("reventa_fisica", true)', self.helper)
        self.assertNotIn("Inventario.HOME_STORAGE", self.helper)

    def test_feedback_transaccion_es_diegetico_y_sin_hud(self):
        self.assertIn('ticket.name = "TicketTransaccion"', self.helper)
        self.assertIn("Label3D.new()", self.helper)
        self.assertIn("EstiloSiga.fuente_mono()", self.helper)
        self.assertIn('"PAGO · -%d"', self.helper)
        self.assertIn('"REVENTA · +%d"', self.helper)
        self.assertIn('"YA COMPRADO"', self.helper)
        self.assertNotIn("CanvasLayer", self.helper)
        self.assertNotIn("Control.new()", self.helper)

    def test_senaletica_original_versionada(self):
        for nombre in ("quiosco_avenida.svg", "el_trastero.svg", "PROCEDENCIA.md"):
            self.assertTrue((ARTE / nombre).exists(), nombre)
        procedencia = (ARTE / "PROCEDENCIA.md").read_text(encoding="utf-8")
        self.assertIn("No usan marcas", procedencia)
        self.assertIn("ComercioBarrio", procedencia)

    def test_runtime_compra_en_ambas_superficies(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="comercio-676-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [
                motor,
                "--headless",
                "--language",
                "es",
                "--path",
                str(ROOT / "godot"),
            ]
            for argumentos, minimo in [
                (["--editor", "--import", "--quit"], None),
                (["--script", PRUEBA], 29),
            ]:
                resultado = subprocess.run(
                    base + argumentos,
                    env=entorno,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    timeout=240,
                    check=False,
                )
                try:
                    validar(
                        resultado.stdout,
                        resultado.returncode,
                        minimo,
                        minimo is None,
                    )
                except ValueError as error:
                    self.fail(f"{error}\n{resultado.stdout}")


if __name__ == "__main__":
    unittest.main()
