from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "godot" / "native" / "siga98_gb"
UI = ROOT / "godot" / "guion" / "emulador_portatil_app.gd"
PORTATIL = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
EXTENSION = ROOT / "godot" / "addons" / "siga98_gb" / "siga98_gb.gdextension"
LOCK = NATIVE / "deps.lock.json"
CI = ROOT / ".github" / "workflows" / "ci.yml"
CHECK_GDSCRIPT = ROOT / "scripts" / "check_gdscript.sh"
ALPHA = ROOT / ".github" / "workflows" / "alpha-playtest.yml"
SMOKE = ROOT / "godot" / "pruebas" / "emulador_gb_smoke.gd"


class EmuladorGBTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cpp = (NATIVE / "src" / "siga98_gb.cpp").read_text(encoding="utf-8")
        cls.ui = UI.read_text(encoding="utf-8")
        cls.portatil = PORTATIL.read_text(encoding="utf-8")
        cls.extension = EXTENSION.read_text(encoding="utf-8")
        cls.lock = json.loads(LOCK.read_text(encoding="utf-8"))
        cls.ci = CI.read_text(encoding="utf-8")
        cls.check_gdscript = CHECK_GDSCRIPT.read_text(encoding="utf-8")
        cls.alpha = ALPHA.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_dependencias_estan_fijadas_y_son_mit(self):
        self.assertEqual(
            self.lock["godot_cpp"]["commit"],
            "6cceaf6a5f8b0d78ac5d71c139fd7fabba43b918",
        )
        self.assertEqual(
            self.lock["peanut_gb"]["commit"],
            "8e656982f08663785794b84823d3e27f856fdb7f",
        )
        self.assertEqual(self.lock["godot_cpp"]["license"], "MIT")
        self.assertEqual(self.lock["peanut_gb"]["license"], "MIT")

    def test_nucleo_rechaza_cgb_only_y_acota_roms(self):
        self.assertIn("CGB_ONLY_FLAG = 0xC0", self.cpp)
        self.assertIn("LOAD_CGB_ONLY", self.cpp)
        self.assertIn("MIN_ROM_SIZE = 32 * 1024", self.cpp)
        self.assertIn("MAX_ROM_SIZE = 8 * 1024 * 1024", self.cpp)

    def test_framebuffer_y_joypad_tienen_contrato_minimo(self):
        self.assertIn("FRAME_WIDTH = 160", self.cpp)
        self.assertIn("FRAME_HEIGHT = 144", self.cpp)
        self.assertIn("gb_run_frame", self.cpp)
        self.assertIn("direct.joypad", self.cpp)
        self.assertIn("run_frame_rgba", self.cpp)

    def test_nucleo_declara_capacidades_para_migracion_cgb(self):
        self.assertIn('D_METHOD("core_name")', self.cpp)
        self.assertIn('D_METHOD("supports_cgb")', self.cpp)
        self.assertIn('D_METHOD("supports_audio")', self.cpp)
        self.assertIn('return "Peanut-GB";', self.cpp)
        self.assertIn("bool Siga98GB::supports_cgb() const", self.cpp)
        self.assertIn("bool Siga98GB::supports_audio() const", self.cpp)

    def test_nucleo_expone_sram_sin_saltarse_tamano_del_cartucho(self):
        self.assertIn('D_METHOD("save_ram")', self.cpp)
        self.assertIn('D_METHOD("load_save_ram", "save")', self.cpp)
        self.assertIn("impl->cart_ram", self.cpp)
        self.assertIn("p_save.size()", self.cpp)
        self.assertIn("Tamaño de SRAM no coincide con el cartucho", self.cpp)

    def test_portatil_abre_ui_sin_estado_de_campana(self):
        self.assertIn("EmuladorPortatilApp.new()", self.portatil)
        combinado = self.cpp + self.ui + self.portatil
        for termino in ("Partida", "Jornada", "pistas_descubiertas", "dinero"):
            self.assertNotIn(termino, combinado)

    def test_ui_usa_rom_propia_y_catalogo_usuario(self):
        self.assertIn("RomsPropias.en_consola(roms_compradas)", self.ui)
        self.assertIn("CatalogoRomsUsuario.listar()", self.ui)
        self.assertIn('ClassDB.class_exists(&"Siga98GB")', self.ui)
        self.assertIn("JOY_BUTTON_DPAD_RIGHT", self.ui)

    def test_ui_reloj_dmg_no_depende_de_fps_godot(self):
        self.assertIn("CICLOS_CPU_DMG := 4194304.0", self.ui)
        self.assertIn("CICLOS_POR_FRAME_DMG := 70224.0", self.ui)
        self.assertIn("FPS_EMULADOR := CICLOS_CPU_DMG / CICLOS_POR_FRAME_DMG", self.ui)
        self.assertIn("PASO_EMULADOR := 1.0 / FPS_EMULADOR", self.ui)
        self.assertIn("MAX_FRAMES_POR_TICK := 4", self.ui)
        self.assertIn("func _process(delta: float)", self.ui)
        self.assertIn("_tiempo_emulador + maxf(delta, 0.0)", self.ui)
        self.assertIn("while _tiempo_emulador >= PASO_EMULADOR", self.ui)
        self.assertIn("_tiempo_emulador -= PASO_EMULADOR", self.ui)
        self.assertNotIn("func _process(_delta: float)", self.ui)

    def test_ui_persiste_sram_por_sha256_fuera_de_la_partida(self):
        self.assertIn('SRAM_DIR := "user://sram/gb"', self.ui)
        self.assertIn("HashingContext.HASH_SHA256", self.ui)
        self.assertIn("hex_encode()", self.ui)
        self.assertIn('_emulador.call("save_ram")', self.ui)
        self.assertIn('_emulador.call("load_save_ram", datos)', self.ui)
        self.assertIn('".nuevo"', self.ui)
        self.assertIn('".anterior"', self.ui)
        self.assertIn('".roto"', self.ui)
        self.assertIn("_recuperar_respaldo_sram()", self.ui)

    def test_presentacion_fisica_es_externa_desactivable_y_cancelable(self):
        self.assertIn("DURACION_ENCENDIDO := 0.32", self.ui)
        self.assertIn("uniform bool filtro_lcd = true", self.ui)
        self.assertIn('set_shader_parameter("filtro_lcd", _efectos_presentacion)', self.ui)
        self.assertIn("func _al_cambiar_efectos(activos: bool)", self.ui)
        self.assertIn("if not _efectos_presentacion:", self.ui)
        self.assertIn("_cargar_rom_ahora(ruta)", self.ui)
        self.assertIn("_rom_pendiente = ruta", self.ui)
        self.assertIn(
            "if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE",
            self.ui,
        )
        self.assertIn("func _cancelar_encendido()", self.ui)
        self.assertIn('var resultado := int(_emulador.call("load_rom", rom))', self.ui)
        self.assertNotIn("Partida", self.ui)
        self.assertNotIn("Jornada", self.ui)

    def test_sonido_fisico_es_procedural_separable_y_desactivable(self):
        self.assertIn("FRECUENCIA_SONIDO_FISICO := 22050", self.ui)
        self.assertIn("AudioStreamPlayer.new()", self.ui)
        self.assertIn("AudioStreamWAV.new()", self.ui)
        self.assertIn("AudioStreamWAV.FORMAT_16_BITS", self.ui)
        self.assertIn("datos.encode_s16(indice * 2, muestra)", self.ui)
        self.assertIn("func _al_cambiar_sonidos(activos: bool)", self.ui)
        self.assertIn('_reproducir_sonido_fisico(&"cartucho")', self.ui)
        self.assertIn('_reproducir_sonido_fisico(&"encendido")', self.ui)
        self.assertIn('_reproducir_sonido_fisico(&"boton")', self.ui)
        self.assertIn("_botones_previos = botones", self.ui)
        self.assertNotIn('_emulador.call("audio', self.ui)

    def test_smoke_compara_pixeles_rgba_no_canales_sueltos(self):
        self.assertIn("BYTES_POR_PIXEL := 4", self.smoke)
        self.assertIn("func _frame_tiene_variacion", self.smoke)
        self.assertIn("frame[indice + canal] != frame[canal]", self.smoke)
        self.assertIn("17, 34, 51, 255, 17, 34, 51, 255", self.smoke)
        self.assertIn("17, 34, 51, 255, 17, 35, 51, 255", self.smoke)
        self.assertIn("if not _frame_tiene_variacion(frame)", self.smoke)

    def test_smoke_ejercita_api_sram_nativa(self):
        self.assertIn("func _probar_sram", self.smoke)
        self.assertIn('emulador.call("save_ram")', self.smoke)
        self.assertIn('emulador.call("load_save_ram", sram)', self.smoke)

    def test_extension_declara_linux_y_windows(self):
        self.assertIn('compatibility_minimum = "4.7"', self.extension)
        self.assertIn("linux.x86_64.single.debug", self.extension)
        self.assertIn("linux.x86_64.single.release", self.extension)
        self.assertIn("windows.x86_64.single.release", self.extension)

    def test_ci_no_lintea_dependencias_descargadas(self):
        self.assertIn("bash scripts/check_gdscript.sh", self.ci)
        self.assertIn("-not -path 'godot/native/siga98_gb/.deps/*'", self.check_gdscript)
        self.assertNotIn("gdlint godot\n", self.ci)

    def test_alpha_importa_antes_del_smoke(self):
        importar = "godot4 --headless --editor --path godot --quit"
        smoke = "godot4 --headless --path godot --script res://pruebas/emulador_gb_smoke.gd"
        self.assertIn(importar, self.alpha)
        self.assertIn(smoke, self.alpha)
        self.assertLess(self.alpha.index(importar), self.alpha.index(smoke))


if __name__ == "__main__":
    unittest.main()
