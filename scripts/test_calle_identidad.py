"""La calle se lee: oficina, tiendas, ventanillas y casa (#277, #398, #93, #85, #43)."""
from pathlib import Path
import csv
import os
import re
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"


class CalleIdentidadTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.identidad = (GUION / "calle_identidad.gd").read_text(encoding="utf-8")
        cls.calle = (GUION / "dia_calle_app.gd").read_text(encoding="utf-8")
        cls.alquiler = (GUION / "dia_alquiler_app.gd").read_text(encoding="utf-8")
        cls.materiales = (GUION / "calle_materiales.gd").read_text(encoding="utf-8")
        cls.ventanilla = (GUION / "ventanilla_app.gd").read_text(encoding="utf-8")
        with (ROOT / "godot/datos/textos.csv").open(encoding="utf-8") as fichero:
            cls.textos = {fila[0]: fila[1] for fila in csv.reader(fichero) if len(fila) >= 2}

    def test_todos_los_rotulos_y_avisos_tienen_texto(self):
        claves = set(re.findall(r'"(CALLE_[A-Z_]+)"', self.identidad))
        # Cada motivo de fallo de la tienda tiene su aviso declarado.
        motivos = set(re.findall(r'_fallo\(id_rom, "(\w+)"\)', (GUION / "tienda_videojuegos.gd").read_text(encoding="utf-8")))
        for motivo in motivos:
            self.assertIn(f'"{motivo}": "CALLE_TIENDA_FALLO_{motivo.upper()}"', self.identidad)
        self.assertTrue(claves)
        for clave in sorted(claves):
            self.assertIn(clave, self.textos, clave)
        self.assertIn("VENTANILLA_SALIR", self.textos)

    def test_la_ventanilla_de_alquiler_es_la_de_la_administracion_de_fincas(self):
        self.assertIn('"pos": Vector3(4.75, 1.1, 9.6)', self.alquiler)
        self.assertNotIn("Vector3(3.55, 1.1, 9.0)", self.alquiler)
        self.assertIn('"VentanillaPago", Vector3(x - 0.09, 1.45, 9.6)', self.identidad.replace("\n\t\t", " ").replace("\n\t", "").replace(",\n", ", "))

    def test_el_coliseo_comparte_la_partida_del_dia(self):
        self.assertIn("ventanilla.partida_externa = partida", self.calle)
        self.assertIn("if not _guardar_o_avisar(\"\"):", self.calle)
        self.assertIn("signal cerrada", self.ventanilla)
        self.assertIn("partida = partida_externa", self.ventanilla)

    def test_las_pieles_de_revoco_cubren_fachadas_reales(self):
        for cara in ("CARA_OESTE_SUR", "CARA_ESTE_SUR", "CARA_OESTE_NORTE"):
            self.assertIn(f'"cara_x": CalleIdentidad.{cara}', self.materiales)
        self.assertEqual(self.materiales.count('"hacia_calle":'), 3)
        self.assertIn("SEPARACION_FACHADA + tam.x * 0.5", self.materiales)
        self.assertNotIn("2.59", self.materiales)

    def test_el_cielo_es_una_noche_urbana_estatica(self):
        cielo = (ROOT / "godot/arte/cielo_siga.gdshader").read_text(encoding="utf-8")
        for uniforme in ("luna_direccion", "resplandor_ciudad", "estrellas"):
            self.assertIn(uniforme, cielo)
        self.assertNotIn("TIME", cielo)

    def test_calle_real_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="calle-identidad-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [motor, "--headless", "--language", "es", "--path", str(ROOT / "godot")]
            for argumentos, minimo in [
                (["--editor", "--import", "--quit"], None),
                (["--script", "res://pruebas/pruebas_calle_identidad.gd"], 60),
            ]:
                resultado = subprocess.run(
                    base + argumentos, env=entorno, text=True, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, timeout=240, check=False,
                )
                try:
                    validar(resultado.stdout, resultado.returncode, minimo, minimo is None)
                except ValueError as error:
                    self.fail(f"{error}\n{resultado.stdout}")


if __name__ == "__main__":
    unittest.main()
