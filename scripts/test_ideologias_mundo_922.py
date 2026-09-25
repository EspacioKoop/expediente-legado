import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRENSA = ROOT / "godot/datos/web98_prensa.json"
RADIO = ROOT / "godot/datos/radio_domestica_98.json"
TV = ROOT / "godot/datos/tv_domestica_98.json"
MODELO_PRENSA = ROOT / "godot/guion/web98_prensa.gd"
NAVEGADOR = ROOT / "godot/guion/navegador_siga.gd"
MINICADENA = ROOT / "godot/guion/minicadena_domestica_98.gd"
TELEVISOR = ROOT / "godot/guion/television_interactiva_3d.gd"
DIALOGO = ROOT / "godot/guion/dialogo_ideologico.gd"
PRUEBA_GODOT = "res://pruebas/issue_922_tv_smoke.gd"


class IdeologiasMundo922Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.prensa = json.loads(PRENSA.read_text(encoding="utf-8"))
        cls.radio = json.loads(RADIO.read_text(encoding="utf-8"))
        cls.tv = json.loads(TV.read_text(encoding="utf-8"))
        cls.modelo_prensa = MODELO_PRENSA.read_text(encoding="utf-8")
        cls.navegador = NAVEGADOR.read_text(encoding="utf-8")
        cls.minicadena = MINICADENA.read_text(encoding="utf-8")
        cls.televisor = TELEVISOR.read_text(encoding="utf-8")
        cls.dialogo = DIALOGO.read_text(encoding="utf-8")

    def test_cuatro_marcos_internos_sin_convertirlos_en_rotulo_visible(self):
        cabeceras = self.prensa["cabeceras"]
        self.assertEqual(
            {cabecera["eje"] for cabecera in cabeceras},
            {"comunismo", "socialdemocrata", "centrista", "neoliberal"},
        )
        for cabecera in cabeceras:
            visible = " ".join(
                [
                    cabecera["nombre"],
                    cabecera["lema"],
                    cabecera["snippet"],
                    *cabecera["prioridades"],
                ]
            ).lower()
            self.assertNotIn(cabecera["eje"], visible)

    def test_prensa_radio_y_tv_comparten_un_hecho_sin_duplicarlo(self):
        hechos = {hecho["id"] for hecho in self.prensa["hechos"]}
        exposiciones_radio = [
            programa["exposicion_ideologica"]
            for emisora in self.radio["emisoras"]
            for programa in emisora["programas"]
            if "exposicion_ideologica" in programa
        ]
        self.assertTrue(exposiciones_radio)
        compartidos_radio = {
            exposicion["hecho_id"] for exposicion in exposiciones_radio
        }
        boletines_tv = [
            bloque["boletin"]
            for bloque in self.tv["bloques"]
            if "boletin" in bloque
        ]
        self.assertTrue(boletines_tv)
        compartidos_tv = {boletin["hecho_id"] for boletin in boletines_tv}
        self.assertLessEqual(compartidos_radio, hechos)
        self.assertLessEqual(compartidos_tv, hechos)
        self.assertIn("turnos-atencion-planta4", compartidos_radio)
        self.assertIn("turnos-atencion-planta4", compartidos_tv)

    def test_cada_tratamiento_sigue_limitado_a_datos_del_hecho_base(self):
        hechos = {hecho["id"]: hecho for hecho in self.prensa["hechos"]}
        for tratamiento in self.prensa["tratamientos"]:
            ids = {dato["id"] for dato in hechos[tratamiento["hecho_id"]]["datos"]}
            self.assertLessEqual(set(tratamiento["datos_destacados"]), ids)
            self.assertLessEqual(set(tratamiento["omisiones"]), ids)

    def test_tratamiento_tv_solo_referencia_datos_del_hecho_base(self):
        hechos = {hecho["id"]: hecho for hecho in self.prensa["hechos"]}
        for bloque in self.tv["bloques"]:
            boletin = bloque.get("boletin", {})
            if not boletin:
                continue
            ids = {
                dato["id"]
                for dato in hechos[boletin["hecho_id"]]["datos"]
            }
            tratamiento = boletin["tratamiento"]
            self.assertLessEqual(set(tratamiento["datos_destacados"]), ids)
            self.assertLessEqual(set(tratamiento["omisiones"]), ids)

    def test_consumo_real_delega_en_el_contrato_de_exposicion(self):
        self.assertIn("registrar_exposicion_portada", self.modelo_prensa)
        self.assertIn("Prometeo", self.modelo_prensa)
        self.assertIn("_registrar_exposicion_prensa(cabecera_id)", self.navegador)
        self.assertIn("_activar_exposicion(contenido)", self.minicadena)
        self.assertIn("registrar_exposicion_de_contenido", self.minicadena)
        self.assertIn("_activar_exposicion_tv(jornada_actual)", self.televisor)
        self.assertIn("registrar_exposicion_de_bloque", self.televisor)

    def test_exposicion_puede_cambiar_un_dialogo_sin_ser_eleccion(self):
        self.assertIn("SUPERFICIE_CAREO_EXPOSICION", self.dialogo)
        self.assertIn('"requiere_exposicion"', self.dialogo)
        self.assertIn("Prometeo.CLAVE_EXPOSICION_IDEOLOGICA", self.dialogo)

    def test_runtime_tv_standalone(self):
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="ideologia-922-tv-") as temporal:
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
                    PRUEBA_GODOT,
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=30,
                check=False,
            )

        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"issue_922_tv: \d+ pasadas, 0 fallos")
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)

    def test_las_superficies_no_escriben_elecciones_por_sus_medios(self):
        for fuente in (
            self.modelo_prensa,
            self.navegador,
            self.minicadena,
            self.televisor,
        ):
            self.assertNotIn("registrar_eleccion_ideologica(", fuente)
            self.assertNotIn('["elecciones_ideologicas_run"] =', fuente)


if __name__ == "__main__":
    unittest.main()
