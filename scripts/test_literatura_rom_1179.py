from pathlib import Path
import json
import os
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot/datos/literatura_obras.json"
ROMS = ROOT / "godot/datos/roms_propias.json"
ACCESO = ROOT / "godot/guion/literatura_roms.gd"
OBSERVER = ROOT / "godot/guion/literatura_rom_vigilia.gd"
FACHADA = ROOT / "godot/guion/sueno_98_vigilia.gd"
CONTROLLER = ROOT / "godot/guion/dia_literatura_rom_app.gd"
GESTOR = ROOT / "godot/literatura/gestor_literatura.gd"
CONSOLA = ROOT / "godot/guion/consola_portatil_98.gd"
DIA = ROOT / "godot/escenas/dia.tscn"
DOC = ROOT / "docs/literatura-rom-sueno-1179.md"
ROM_SOURCE = ROOT / "gbc/minijuegos/sueno_98/main.asm"
TEST_GODOT = "res://pruebas/pruebas_literatura_rom_1179.gd"


class LiteraturaRom1179Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        cls.roms = json.loads(ROMS.read_text(encoding="utf-8"))["roms"]
        cls.acceso = ACCESO.read_text(encoding="utf-8")
        cls.observer = OBSERVER.read_text(encoding="utf-8")
        cls.fachada = FACHADA.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.gestor = GESTOR.read_text(encoding="utf-8")
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")
        cls.rom_source = ROM_SOURCE.read_text(encoding="utf-8")

    def test_catalogos_declaran_rom_jugable_sin_tienda(self):
        obra = self.catalogo["obras"][0]
        self.assertEqual(obra["rom"]["id"], "sueno_98")
        self.assertEqual(obra["rom"]["estado"], "jugable")
        self.assertEqual(obra["rom"]["desbloqueo"], "conocimiento")
        sueno = next(rom for rom in self.roms if rom["id"] == "sueno_98")
        self.assertEqual(sueno["estado"], "jugable")
        self.assertEqual(sueno["precio"], 0)
        self.assertFalse(sueno["incluida"])
        self.assertEqual(
            sueno["desbloqueo"],
            "conocimiento:vida_es_sueno_1635",
        )

    def test_acceso_solo_consulta_conocimiento(self):
        self.assertIn("LiteraturaEventos.obra_conocida", self.acceso)
        self.assertIn('String(rom.get("desbloqueo", "")) != "conocimiento"', self.acceso)
        self.assertNotIn("obra_poseida", self.acceso)
        self.assertNotIn("CANAL_INSIGHT", self.acceso)

    def test_consola_y_emulador_siguen_genericos(self):
        self.assertIn("func desbloquear_rom(id_rom: String) -> bool:", self.consola)
        self.assertIn("_app.roms_desbloqueadas", self.consola)
        combinado = self.consola + self.controller
        self.assertNotIn("LiteraturaEventos", self.consola)
        self.assertNotIn("vida_es_sueno_1635", self.consola)
        self.assertIn("LiteraturaRoms.desbloqueadas(registro)", self.controller)
        self.assertIn("consola.desbloquear_rom", self.controller)
        self.assertIn("Sueno98Vigilia", combinado)

    def test_observer_no_puede_convertir_rom_en_conocimiento(self):
        self.assertIn("LiteraturaEventos.CANAL_INSIGHT", self.observer)
        self.assertNotIn("LiteraturaEventos.CANAL_CONOCIMIENTO", self.observer)
        self.assertIn("registrar_evento_externo", self.observer)
        metodo = self.gestor.split("func registrar_evento_externo", 1)[1].split(
            "\n\nfunc ", 1
        )[0]
        self.assertIn("LiteraturaEventos.CANAL_CONOCIMIENTO", metodo)
        self.assertIn("return false", metodo)

    def test_handshake_es_externo_y_solo_objetivo_final(self):
        self.assertIn("DIRECCION_ESTADO := 0xC100", self.fachada)
        self.assertIn("ESTADO_COMPLETADO := 0xA5", self.fachada)
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.rom_source)
        bloque = self.rom_source.split("CompletarObjetivoFinal:", 1)[1].split(
            "DibujarTitulo:", 1
        )[0]
        self.assertIn("ld [wSuenoCompletado], a", bloque)
        prefijo = self.rom_source.split("CompletarObjetivoFinal:", 1)[0]
        self.assertNotIn("ld [wSuenoCompletado], a", prefijo.split("Inicio:", 1)[1].replace(
            "ld [wSuenoCompletado], a\n", "", 1
        ))

    def test_controller_esta_montado_en_dia(self):
        self.assertIn('path="res://guion/dia_literatura_rom_app.gd"', self.dia)
        self.assertIn('[node name="LiteraturaRomController"', self.dia)

    def test_documentacion_separa_fuente_adaptacion_e_invencion(self):
        for titulo in ("## 1. Obra fuente", "## 2. Adaptación", "## 3. Invención propia"):
            self.assertIn(titulo, self.doc)
        self.assertIn("no incorpora texto de la obra", self.doc)
        self.assertIn("idempotente", self.doc)

    def test_godot_contract(self):
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="literatura-rom-1179-") as tmp:
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
