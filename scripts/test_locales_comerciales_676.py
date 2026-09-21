"""Locales físicos y accesibles del comercio de barrio (#676)."""

from pathlib import Path
import csv
import os
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"
ARTE_BIT98 = ROOT / "godot/arte/bit98"


class LocalesComerciales676Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.locales = (GUION / "calle_locales_comerciales_3d.gd").read_text(
            encoding="utf-8"
        )
        cls.identidad = (GUION / "calle_identidad.gd").read_text(encoding="utf-8")
        cls.calle = (GUION / "dia_calle_app.gd").read_text(encoding="utf-8")
        cls.bit98 = (GUION / "bit98_dressing.gd").read_text(encoding="utf-8")
        with (ROOT / "godot/datos/textos.csv").open(encoding="utf-8") as fichero:
            cls.textos = {
                fila[0]: fila[1] for fila in csv.reader(fichero) if len(fila) >= 2
            }

    def test_dia_monta_los_locales_sobre_la_calle_real(self):
        self.assertIn("CalleLocalesComerciales3D.montar(self, calle)", self.calle)
        self.assertIn('const NOMBRE := "LocalesComerciales"', self.locales)
        self.assertIn('interior.name = "InteriorElectrodomesticos"', self.locales)
        self.assertIn('interior.name = "InteriorBit98"', self.locales)

    def test_entrar_no_crea_otra_fase_ni_economia(self):
        self.assertNotIn('jornada["fase"]', self.locales)
        self.assertNotIn("Jornada.gastar", self.locales)
        self.assertNotIn("Partida.", self.locales)
        self.assertIn('dia._entrar_en("trayecto")', (
            ROOT / "godot/pruebas/pruebas_locales_comerciales_676.gd"
        ).read_text(encoding="utf-8"))
        self.assertIn('String(dia.jornada["fase"]) == fase_inicial', (
            ROOT / "godot/pruebas/pruebas_locales_comerciales_676.gd"
        ).read_text(encoding="utf-8"))

    def test_las_puertas_exteriores_entran_y_no_compran(self):
        self.assertIn('"EntrarElectrodomesticos"', self.locales)
        self.assertIn('"EntrarTiendaVideojuegos"', self.locales)
        self.assertIn(
            'fachada.get_node_or_null("ComprarCartuchos") as Interactuable3D',
            self.locales,
        )
        self.assertIn('puerta.name = "EntrarTiendaVideojuegos"', self.locales)
        self.assertIn("puerta.activado.disconnect(llamada)", self.locales)
        self.assertIn("puerta.verbo = Interactuable3D.Verbo.ABRIR", self.locales)

    def test_compra_de_videojuegos_vive_en_mostrador_interior(self):
        self.assertIn('"ComprarCartuchos"', self.locales)
        self.assertIn(
            "CalleIdentidad._comprar_cartucho.bind(compra)",
            self.locales,
        )
        self.assertIn('"MostradorBit98"', self.locales)
        self.assertIn('"CajaJuego_%d_%d_%d"', self.locales)
        self.assertIn("for juego in 5:", self.locales)

    def test_electrodomesticos_gana_exposicion_y_variedad(self):
        for rasgo in (
            '"SueloExposicion"',
            '"FondoEscaparate"',
            '"EscaparateProfundo"',
            '"Cartela%d_%d"',
        ):
            self.assertIn(rasgo, self.locales)
        self.assertIn('"Frigorifico%d"', self.locales)
        self.assertIn('"Lavadora%d"', self.locales)
        self.assertIn('"TeleInterior%d"', self.locales)

    def test_bit98_gana_profundidad_de_escaparate(self):
        for rasgo in (
            '"FondoEscaparate"',
            '"BaldaEscaparate%d"',
            '"CajaCartucho%d"',
        ):
            self.assertIn(rasgo, self.locales)
        self.assertIn('frente.visible = false', self.locales)
        self.assertIn('cartucho_plano.visible = false', self.locales)
        self.assertNotIn('"pos": Vector3(6.5, 5.0, -10.65)', self.calle)
        self.assertIn('"pos": Vector3(6.5, 6.5, -10.65)', self.calle)
        self.assertIn("hueco real en planta baja para Bit 98", self.calle)

    def test_bit98_usa_identidad_original_y_portadas_existentes(self):
        self.assertIn("Bit98Dressing.montar(calle)", self.calle)
        for asset in (
            "rotulo_bit98.svg",
            "cartel_juega.svg",
            "cartel_segunda_mano.svg",
            "cartel_novedades.svg",
            "PROCEDENCIA.md",
        ):
            self.assertTrue((ARTE_BIT98 / asset).exists(), asset)
        for portada in (
            "caza_pixeles_98.jpg",
            "paper_planes_98.jpg",
            "croc_riders_98.jpg",
        ):
            self.assertIn(portada, self.bit98)
        self.assertIn('"RotuloBit98Exterior"', self.bit98)
        self.assertIn('"RotuloBit98Interior"', self.bit98)
        self.assertIn('"ExpositorPortadasPropias"', self.bit98)
        self.assertNotIn("TiendaVideojuegos.comprar", self.bit98)
        self.assertNotIn("Jornada.gastar", self.bit98)

    def test_textos_de_puerta_existen(self):
        for clave in (
            "CALLE_PUERTA_ELECTRODOMESTICOS",
            "CALLE_PUERTA_VIDEOJUEGOS",
            "CALLE_PUERTA_SALIDA",
        ):
            self.assertIn(clave, self.textos)
            self.assertTrue(self.textos[clave].strip())

    def test_locales_reales_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="locales-676-qa-") as temporal:
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
                (
                    ["--script", "res://pruebas/pruebas_locales_comerciales_676.gd"],
                    20,
                ),
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
