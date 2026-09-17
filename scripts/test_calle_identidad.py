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

    def test_ventanas_altas_no_solapan_la_piel_de_revoco(self):
        def constante(texto, nombre):
            coincidencia = re.search(rf"const {nombre} := ([0-9.]+)", texto)
            self.assertIsNotNone(coincidencia, nombre)
            return float(coincidencia.group(1))

        separacion = constante(self.materiales, "SEPARACION_FACHADA")
        grosor_piel = constante(self.materiales, "GROSOR_PIEL_FACHADA")
        saliente_ventana = constante(self.identidad, "SALIENTE_VENTANA_FACHADA")
        grosor_ventana = constante(self.identidad, "GROSOR_VENTANA_FACHADA")
        borde_exterior_piel = separacion + grosor_piel
        borde_interior_ventana = saliente_ventana - grosor_ventana / 2.0

        self.assertGreaterEqual(borde_interior_ventana - borde_exterior_piel, 0.01)
        self.assertIn("cara + hacia * SALIENTE_VENTANA_FACHADA", self.identidad)
        self.assertIn("Vector3(GROSOR_VENTANA_FACHADA, 1.2, 0.9)", self.identidad)
        self.assertNotIn("cara + hacia * 0.03", self.identidad)

    def test_el_cielo_es_una_noche_urbana_estatica(self):
        cielo = (ROOT / "godot/arte/cielo_siga.gdshader").read_text(encoding="utf-8")
        preset = (ROOT / "godot/arte/cielo_siga.tres").read_text(encoding="utf-8")
        for uniforme in (
            "luna_direccion",
            "luna_halo",
            "resplandor_ciudad",
            "resplandor_direccion",
            "resplandor_asimetria",
            "bruma_horizonte",
            "nubes",
            "cirros",
            "luz_lunar_nubes",
            "via_lactea",
            "estrellas",
            "estrellas_secundarias",
        ):
            self.assertIn(uniforme, cielo)
        for parametro in (
            "luna_halo",
            "resplandor_direccion",
            "resplandor_asimetria",
            "bruma_fuerza",
            "nubes",
            "cirros",
            "luz_lunar_nubes",
            "via_lactea",
            "estrellas_secundarias",
        ):
            self.assertIn(f"shader_parameter/{parametro}", preset)
        for rasgo in (
            "foco_ciudad",
            "mascara_nube",
            "mascara_cirro",
            "banda_via",
            "color_estrella",
        ):
            self.assertIn(rasgo, cielo)
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
