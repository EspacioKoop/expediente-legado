import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
INDICE = ROOT / "godot" / "datos" / "roms_propias.json"
VIGILIA = ROOT / "godot" / "guion" / "webkeeper_98_vigilia.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_anansi_akan_app.gd"
ROM = ROOT / "gbc" / "minijuegos" / "webkeeper_98" / "main.asm"
README_ROM = ROOT / "gbc" / "minijuegos" / "webkeeper_98" / "README.md"
DOCS = ROOT / "docs" / "roms-propias.md"
PRUEBA_GODOT = "res://pruebas/pruebas_webkeeper_vigilia_748.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class WebkeeperRuntime748Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        datos = json.loads(INDICE.read_text(encoding="utf-8"))
        cls.webkeeper = next(r for r in datos["roms"] if r["id"] == "webkeeper_98")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.rom = ROM.read_text(encoding="utf-8")
        cls.readme = README_ROM.read_text(encoding="utf-8")
        cls.docs = DOCS.read_text(encoding="utf-8")

    def test_webkeeper_entra_en_build_y_tienda(self):
        self.assertEqual(self.webkeeper["estado"], "jugable")
        self.assertEqual(self.webkeeper["rom"], "res://roms/webkeeper_98.gbc")
        self.assertEqual(self.webkeeper["cabecera"], "WEBKEEPER98")
        self.assertEqual(self.webkeeper["cgb"], "dual")
        self.assertFalse(self.webkeeper["incluida"])
        self.assertEqual(self.webkeeper["precio"], 45)
        self.assertEqual(self.webkeeper["mito"], "anansi_akan")

    def test_fachada_declara_abi_sin_acoplar_emulador(self):
        self.assertIn('extends "res://guion/semilla_rom_vigilia.gd"', self.vigilia)
        self.assertIn('const ID_ROM := "webkeeper_98"', self.vigilia)
        self.assertIn('const ID_MITO := "anansi_akan"', self.vigilia)
        self.assertIn('const TITULO_ROM := "WEBKEEPER98"', self.vigilia)
        self.assertIn("const DIRECCION_COMPLETADO := 0xC100", self.vigilia)
        self.assertIn("const MARCA_COMPLETADO := 0xA5", self.vigilia)
        self.assertIn("configurar_contrato(", self.vigilia)

    def test_controller_real_reintenta_hasta_encontrar_portatil(self):
        self.assertIn('String(dia.jornada.get("fase", ""))', self.controller)
        self.assertIn("_montar_observador_webkeeper", self.controller)
        self.assertIn('get_node_or_null("ConsolaPortatil98")', self.controller)
        self.assertIn("Webkeeper98Vigilia.new()", self.controller)
        self.assertIn("observador.configurar(jornada, consola)", self.controller)

    def test_rom_solo_publica_marca_al_ganar_final(self):
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.rom)
        inicio = self.rom.split("Inicio:", 1)[1].split("BuclePrincipal:", 1)[0]
        self.assertIn("ld [wWebkeeperCompletado], a", inicio)

        campeon = self.rom.split(".campeon:", 1)[1].split("TotalTirosActual:", 1)[0]
        self.assertIn("ld a, MARCA_COMPLETADO", campeon)
        self.assertIn("ld [wWebkeeperCompletado], a", campeon)

        derrota = self.rom.split(".derrota:", 1)[1].split(".campeon:", 1)[0]
        self.assertNotIn("wWebkeeperCompletado", derrota)

    def test_documentacion_refleja_promocion_y_fuente(self):
        self.assertIn("| " + chr(96) + "webkeeper_98" + chr(96) + " | Kwaku, el guardameta |", self.docs)
        self.assertIn("tienda de videojuegos | 45", self.docs)
        self.assertIn(chr(96) + "Webkeeper98Vigilia" + chr(96), self.docs)
        self.assertIn(chr(96) + "rom:webkeeper_98" + chr(96), self.docs)
        self.assertIn("ROM jugable del catálogo", self.readme)
        self.assertIn("comprar o arrancar la ROM no activa nada", self.readme)

    def test_handshake_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 9, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
