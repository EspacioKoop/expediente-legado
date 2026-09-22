"""Índice operativo de ROMs propias: una sola lista para build, tienda, consola y sueños."""
from pathlib import Path
import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
INDICE = ROOT / "godot/datos/roms_propias.json"
DOC = ROOT / "docs/roms-propias.md"
MINIJUEGOS = ROOT / "gbc/minijuegos"
MITOS = re.findall(r'"(\w+)"', (ROOT / "godot/guion/SemillasOniricas.gd").read_text(encoding="utf-8").split("const MITOS_VALIDOS := [", 1)[1].split("]", 1)[0])


class RomsPropiasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.roms = json.loads(INDICE.read_text(encoding="utf-8"))["roms"]
        cls.por_id = {rom["id"]: rom for rom in cls.roms}

    def test_ids_unicos_y_estados_conocidos(self):
        self.assertEqual(len(self.por_id), len(self.roms))
        for rom in self.roms:
            with self.subTest(rom=rom["id"]):
                self.assertRegex(rom["id"], r"^[a-z0-9_]+$")
                self.assertIn(rom["estado"], ("jugable", "en_proyecto"))
                self.assertTrue(rom["titulo"].strip())
                self.assertTrue(rom["issues"])
                if rom["mito"]:
                    self.assertIn(rom["mito"], MITOS)

    def test_minimos_acordados(self):
        for id_rom in ("caza_pixeles_98", "paper_planes_98", "croc_riders_98"):
            self.assertEqual(self.por_id[id_rom]["estado"], "jugable", id_rom)
        self.assertTrue([r for r in self.roms if r["estado"] == "en_proyecto"])

    def test_cada_fuente_de_gbc_minijuegos_esta_indexada_y_viceversa(self):
        carpetas = {p.name for p in MINIJUEGOS.iterdir() if (p / "Makefile").exists()}
        con_fuente = {r["id"] for r in self.roms if r["fuente"]}
        self.assertEqual(carpetas, con_fuente)
        for rom in self.roms:
            with self.subTest(rom=rom["id"]):
                if rom["fuente"]:
                    self.assertEqual(rom["fuente"], f"gbc/minijuegos/{rom['id']}")
                    makefile = (ROOT / rom["fuente"] / "Makefile").read_text(encoding="utf-8")
                    self.assertIn(f"ROM := build/{rom['id']}.gbc", makefile)
                    self.assertTrue((ROOT / rom["fuente"] / "README.md").exists())
                    self.assertTrue(rom["cabecera"])
                    self.assertLessEqual(len(rom["cabecera"]), 15)
                    self.assertIn(rom["cgb"], ("dual", "solo"))
                else:
                    self.assertEqual((rom["cabecera"], rom["cgb"]), ("", ""))

                if rom["estado"] == "jugable":
                    self.assertTrue(rom["fuente"])
                    self.assertEqual(rom["rom"], f"res://roms/{rom['id']}.gbc")
                else:
                    # Un proyecto puede tener ya una fuente prototipo verificable sin
                    # entrar todavía en build/runtime. Mientras siga en proyecto no se
                    # vende, no se incluye y no tiene ruta de ROM consumible por Godot.
                    self.assertEqual((rom["rom"], rom["precio"]), ("", 0))
                    self.assertFalse(rom["incluida"])

    def test_la_consola_trae_una_y_la_tienda_vende_el_resto(self):
        incluidas = [r for r in self.roms if r["incluida"]]
        self.assertEqual([r["id"] for r in incluidas], ["caza_pixeles_98"])
        for rom in self.roms:
            if rom["estado"] == "jugable" and not rom["incluida"]:
                self.assertGreater(rom["precio"], 0, rom["id"])

    def test_build_y_workflows_respetan_estado_y_fuentes(self):
        preparar = (ROOT / "scripts/preparar_emulador_gb.sh").read_text(encoding="utf-8")
        self.assertIn("godot/datos/roms_propias.json", preparar)
        self.assertIn('rom["estado"] == "jugable"', preparar)
        fixtures = (ROOT / ".github/workflows/gbc-fixtures.yml").read_text(encoding="utf-8")
        for rom in self.roms:
            if rom["fuente"]:
                self.assertIn(f"{rom['fuente']}", fixtures, rom["id"])

    def test_toda_fuente_rom_citada_en_codigo_esta_en_el_indice(self):
        citadas = set()
        for ruta in (ROOT / "godot/guion").glob("*.gd"):
            citadas |= set(re.findall(r'"rom:([a-z0-9_]+)"', ruta.read_text(encoding="utf-8")))
            citadas |= set(re.findall(r'res://roms/([a-z0-9_]+)\.gbc', ruta.read_text(encoding="utf-8")))
        self.assertTrue(citadas)
        self.assertLessEqual(citadas, set(self.por_id))

    def test_documento_lista_todas(self):
        texto = DOC.read_text(encoding="utf-8")
        for rom in self.roms:
            self.assertIn(f"`{rom['id']}`", texto)
            self.assertIn(rom["titulo"], texto)

    @unittest.skipUnless(shutil.which("rgbasm"), "RGBDS no instalado")
    def test_las_fuentes_compilan_con_la_cabecera_declarada(self):
        for rom in self.roms:
            if not rom["fuente"]:
                continue
            with self.subTest(rom=rom["id"]):
                fuente = ROOT / rom["fuente"]
                subprocess.run(["make", "-s", "-C", str(fuente), "all"], check=True, capture_output=True)
                datos = (fuente / "build" / f"{rom['id']}.gbc").read_bytes()
                self.assertEqual(datos[0x134:0x143].rstrip(b"\0").decode("ascii"), rom["cabecera"])
                self.assertEqual(datos[0x143], 0x80 if rom["cgb"] == "dual" else 0xC0)

    def test_indice_en_godot(self):
        ausentes = []
        for rom in self.roms:
            if rom["estado"] != "jugable" or not rom["rom"].startswith("res://"):
                continue
            ruta = ROOT / "godot" / rom["rom"].removeprefix("res://")
            if not ruta.exists():
                ausentes.append(rom["id"])
        if ausentes:
            mensaje = (
                "faltan ROMs propias compiladas para el runtime: "
                + ", ".join(ausentes)
                + "; ejecuta bash scripts/preparar_entorno.sh"
            )
            if os.environ.get("SIGA98_EXIGIR_EXTENSION") == "1":
                self.fail(mensaje)
            self.skipTest(mensaje)

        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="roms-propias-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [motor, "--headless", "--language", "es", "--path", str(ROOT / "godot")]
            for argumentos, minimo in [
                (["--editor", "--import", "--quit"], None),
                (["--script", "res://pruebas/pruebas_roms_propias.gd"], 20),
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
