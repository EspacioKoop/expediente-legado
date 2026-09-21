from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "godot" / "native" / "siga98_gb"
UI = ROOT / "godot" / "guion" / "emulador_portatil_app.gd"
AUDIO_UI = ROOT / "godot" / "guion" / "emulador_portatil_audio_app.gd"
AFTERGLOW = ROOT / "godot" / "guion" / "efecto_apagado_portatil.gd"
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
        cls.audio_ui = AUDIO_UI.read_text(encoding="utf-8")
        cls.afterglow = AFTERGLOW.read_text(encoding="utf-8")
        cls.portatil = PORTATIL.read_text(encoding="utf-8")
        cls.extension = EXTENSION.read_text(encoding="utf-8")
        cls.lock = json.loads(LOCK.read_text(encoding="utf-8"))
        cls.ci = CI.read_text(encoding="utf-8")
        cls.check_gdscript = CHECK_GDSCRIPT.read_text(encoding="utf-8")
        cls.alpha = ALPHA.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_dependencias_estan_fijadas_y_son_permisivas(self):
        self.assertEqual(
            self.lock["godot_cpp"]["commit"],
            "6cceaf6a5f8b0d78ac5d71c139fd7fabba43b918",
        )
        self.assertEqual(self.lock["godot_cpp"]["license"], "MIT")
        self.assertEqual(self.lock["sameboy"]["license"], "Expat")
        self.assertNotIn("peanut_gb", self.lock)
        self.assertNotIn("peanut_gb.h", self.cpp)

    def test_nucleo_admite_cgb_only_y_acota_roms(self):
        self.assertNotIn("CGB_ONLY_FLAG", self.cpp)
        self.assertIn("LOAD_CGB_ONLY", self.cpp)
        self.assertIn("MIN_ROM_SIZE = 32 * 1024", self.cpp)
        self.assertIn("MAX_ROM_SIZE = 8 * 1024 * 1024", self.cpp)
        self.assertIn("HEADER_CHECKSUM_OFFSET = 0x14D", self.cpp)
        self.assertIn("GB_MODEL_CGB_E", self.cpp)

    def test_framebuffer_y_joypad_tienen_contrato_minimo(self):
        self.assertIn("FRAME_WIDTH = 160", self.cpp)
        self.assertIn("FRAME_HEIGHT = 144", self.cpp)
        self.assertIn("GB_run_frame", self.cpp)
        self.assertIn("GB_set_pixels_output", self.cpp)
        self.assertIn("GB_set_key_state", self.cpp)
        self.assertIn("run_frame_rgba", self.cpp)

    def test_set_buttons_conserva_orden_de_bits_publico(self):
        self.assertIn(
            "GB_KEY_A, GB_KEY_B, GB_KEY_SELECT, GB_KEY_START,\n"
            "    GB_KEY_RIGHT, GB_KEY_LEFT, GB_KEY_UP, GB_KEY_DOWN,",
            self.cpp,
        )
        for constante, valor in (
            ("BTN_A", "0x01"),
            ("BTN_B", "0x02"),
            ("BTN_SELECT", "0x04"),
            ("BTN_START", "0x08"),
            ("BTN_RIGHT", "0x10"),
            ("BTN_LEFT", "0x20"),
            ("BTN_UP", "0x40"),
            ("BTN_DOWN", "0x80"),
        ):
            self.assertIn(f"const {constante} := {valor}", self.ui)

    def test_nucleo_declara_capacidades_cgb_y_audio(self):
        self.assertIn('D_METHOD("core_name")', self.cpp)
        self.assertIn('D_METHOD("supports_cgb")', self.cpp)
        self.assertIn('D_METHOD("supports_audio")', self.cpp)
        self.assertIn('return "SameBoy";', self.cpp)
        self.assertIn("bool Siga98GB::supports_cgb() const", self.cpp)
        self.assertIn("bool Siga98GB::supports_audio() const", self.cpp)
        self.assertIn(
            "bool Siga98GB::supports_audio() const {\n    return true;\n}",
            self.cpp,
        )

    def test_nucleo_expone_sram_sin_saltarse_tamano_del_cartucho(self):
        self.assertIn('D_METHOD("save_ram")', self.cpp)
        self.assertIn('D_METHOD("load_save_ram", "save")', self.cpp)
        self.assertIn("GB_save_battery_size", self.cpp)
        self.assertIn("GB_load_battery_from_buffer", self.cpp)
        self.assertIn("p_save.size()", self.cpp)
        self.assertIn("Tamaño de SRAM no coincide con el cartucho", self.cpp)

    def test_portatil_abre_ui_sin_estado_de_campana(self):
        self.assertIn("EmuladorPortatilAudioApp.new()", self.portatil)
        self.assertIn("extends EmuladorPortatilApp", self.audio_ui)
        combinado = self.cpp + self.ui + self.audio_ui + self.portatil
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

    def test_ui_deriva_sram_del_contenido_no_de_ruta_ni_nombre(self):
        self.assertIn("func _ruta_sram(rom: PackedByteArray) -> String:", self.ui)
        cuerpo_ruta_sram = self.ui.split("func _ruta_sram(rom: PackedByteArray) -> String:", 1)[
            1
        ].split("func ", 1)[0]
        self.assertNotIn("ruta", cuerpo_ruta_sram)
        self.assertNotIn("get_file()", cuerpo_ruta_sram)

    def test_ui_cambia_de_rom_sin_mezclar_sram(self):
        cuerpo_cargar_rom = self.ui.split("func _cargar_rom(ruta: String) -> void:", 1)[
            1
        ].split("func ", 1)[0]
        indice_guardar = cuerpo_cargar_rom.index("_guardar_sram()")
        indice_reset_ruta = cuerpo_cargar_rom.index('_ruta_sram_actual = ""')
        indice_carga = cuerpo_cargar_rom.index("_cargar_rom_ahora(ruta)")
        self.assertLess(
            indice_guardar,
            indice_reset_ruta,
            "la SRAM de la ROM saliente debe guardarse antes de soltar su ruta",
        )
        self.assertLess(
            indice_reset_ruta,
            indice_carga,
            "_ruta_sram_actual debe limpiarse antes de cargar la ROM entrante",
        )

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

    def test_apagado_fisico_es_capa_externa_y_no_bloquea_la_salida(self):
        self.assertIn("class_name EfectoApagadoPortatil", self.afterglow)
        self.assertIn("extends CanvasLayer", self.afterglow)
        self.assertIn("DURACION_AFTERGLOW := 0.18", self.afterglow)
        self.assertIn("Node.PROCESS_MODE_ALWAYS", self.afterglow)
        self.assertIn("Control.MOUSE_FILTER_IGNORE", self.afterglow)
        self.assertNotIn("Siga98GB", self.afterglow)
        self.assertNotIn("SRAM", self.afterglow)
        self.assertIn("get_tree().root.add_child(efecto)", self.ui)
        cuerpo = self.ui.split("func _cerrar() -> void:", 1)[1].split("func ", 1)[0]
        self.assertIn("_lanzar_apagado_fisico()", cuerpo)
        self.assertIn("get_tree().paused = _pausa_anterior", cuerpo)
        self.assertIn("cerrado.emit()", cuerpo)
        self.assertIn("queue_free()", cuerpo)
        self.assertLess(
            cuerpo.index("get_tree().paused = _pausa_anterior"),
            cuerpo.index("queue_free()"),
        )

    def test_variacion_lcd_es_pequena_determinista_y_desactivable(self):
        self.assertIn("uniform float variacion_brillo = 0.0", self.ui)
        self.assertIn("rgb *= 1.0 + variacion_brillo", self.ui)
        self.assertIn("sin(_tiempo_presentacion * 1.7) * 0.012", self.ui)
        self.assertIn(
            'set_shader_parameter("variacion_brillo", 0.0)',
            self.ui,
        )
        cuerpo = self.ui.split(
            "func _actualizar_variacion_lcd(delta: float) -> void:", 1
        )[1].split("func ", 1)[0]
        self.assertNotIn("rand", cuerpo)
        self.assertNotIn("_emulador.call", cuerpo)

    def test_apagado_tiene_click_fisico_separado_del_audio_de_rom(self):
        self.assertIn(
            '&"apagado": _crear_sonido_fisico(230.0, 72.0, 0.065, 0.50)',
            self.ui,
        )
        self.assertIn('get(&"apagado")', self.ui)
        self.assertIn('name = "ClickApagadoPortatil"', self.afterglow)
        self.assertIn("AudioStreamPlayer.new()", self.afterglow)

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

    def test_audio_rom_usa_generator_separado_acotado_y_limpiable(self):
        self.assertIn("AudioStreamGenerator.new()", self.audio_ui)
        self.assertIn('name = "AudioEmuladoPortatil"', self.audio_ui)
        self.assertIn("AudioStreamGeneratorPlayback", self.audio_ui)
        self.assertIn('call("drain_audio_pcm16")', self.audio_ui)
        self.assertIn("pcm.decode_s16(offset)", self.audio_ui)
        self.assertIn("pcm.decode_s16(offset + 2)", self.audio_ui)
        self.assertIn("get_frames_available()", self.audio_ui)
        self.assertIn("push_buffer(lote)", self.audio_ui)
        self.assertIn("MAX_FRAMES_AUDIO_PENDIENTE := 9600", self.audio_ui)
        self.assertIn("clear_buffer()", self.audio_ui)
        self.assertIn("func set_audio_emulado_muted(muted: bool)", self.audio_ui)
        self.assertIn("func set_audio_emulado_volumen(volumen: float)", self.audio_ui)
        self.assertIn("func _cargar_rom(ruta: String)", self.audio_ui)
        self.assertIn("func _cerrar()", self.audio_ui)
        self.assertIn("func _exit_tree()", self.audio_ui)
        self.assertNotIn("AudioStreamWAV", self.audio_ui)

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

    def test_smoke_exige_audio_nativo_activo(self):
        self.assertIn('if not bool(emulador.call("supports_audio")):', self.smoke)
        self.assertIn('emulador.call("drain_audio_pcm16")', self.smoke)
        self.assertIn("BYTES_POR_MUESTRA_ESTEREO := 4", self.smoke)
        self.assertIn("FRECUENCIA_AUDIO := 48000", self.smoke)

    def test_extension_declara_linux_y_windows(self):
        self.assertIn('compatibility_minimum = "4.7"', self.extension)
        self.assertIn("linux.x86_64.single.debug", self.extension)
        self.assertIn("linux.x86_64.single.release", self.extension)
        self.assertIn("windows.x86_64.single.release", self.extension)

    def test_ci_no_lintea_dependencias_descargadas(self):
        self.assertIn("bash scripts/check_gdscript.sh", self.ci)
        self.assertIn("-not -path 'godot/native/siga98_gb/.deps/*'", self.check_gdscript)
        self.assertNotIn("gdlint godot\n", self.ci)

    def test_smoke_espera_a_la_boot_rom(self):
        self.assertIn("const FRAMES_ARRANQUE := 60", self.smoke)
        self.assertIn("range(FRAMES_ARRANQUE)", self.smoke)

    def test_ci_arranca_rom_dmg_only_y_mantiene_los_tres_modos(self):
        self.assertIn("make -C gbc/fixtures/dmg_only_smoke clean all", self.ci)
        self.assertIn("res://pruebas/emulador_dmg_smoke.gd", self.ci)
        dmg = (ROOT / "godot" / "pruebas" / "emulador_dmg_smoke.gd").read_text(encoding="utf-8")
        fixture = (ROOT / "gbc" / "fixtures" / "dmg_only_smoke" / "main.asm").read_text(
            encoding="utf-8"
        )
        caza = (ROOT / "gbc" / "minijuegos" / "caza_pixeles_98" / "main.asm").read_text(
            encoding="utf-8"
        )
        self.assertIn("rom[0x143]) != 0x00", dmg)
        self.assertIn('emulador.call("core_name")', dmg)
        self.assertIn("_frame_tiene_variacion(frame)", dmg)
        self.assertIn("db $00 ; DMG-only", fixture)
        self.assertIn("db $80 ; ROM compatible con Game Boy Color.", caza)
        self.assertIn("make -C gbc/fixtures/cgb_only_smoke clean all", self.ci)

    def test_ci_arranca_rom_cgb_only(self):
        self.assertIn("make -C gbc/fixtures/cgb_only_smoke clean all", self.ci)
        self.assertIn("res://pruebas/emulador_gbc_smoke.gd", self.ci)
        gbc = (ROOT / "godot" / "pruebas" / "emulador_gbc_smoke.gd").read_text(encoding="utf-8")
        self.assertIn('emulador.call("supports_cgb")', gbc)
        self.assertIn("rom[0x143] != 0xC0", gbc)
        self.assertIn("_contiene(frame, 0)", gbc)
        self.assertIn("_contiene(frame, 1)", gbc)

    def test_ci_persiste_y_aisla_sram_end_to_end(self):
        self.assertIn("make -C gbc/fixtures/sram_persist_smoke clean all", self.ci)
        self.assertIn("res://pruebas/emulador_sram_smoke.gd", self.ci)
        smoke = (ROOT / "godot" / "pruebas" / "emulador_sram_smoke.gd").read_text(
            encoding="utf-8"
        )
        fixture = (
            ROOT / "gbc" / "fixtures" / "sram_persist_smoke" / "main.asm"
        ).read_text(encoding="utf-8")
        makefile = (
            ROOT / "gbc" / "fixtures" / "sram_persist_smoke" / "Makefile"
        ).read_text(encoding="utf-8")
        self.assertIn("EmuladorPortatilApp.new()", smoke)
        self.assertIn("app.abrir()", smoke)
        self.assertIn('app.call("_cerrar")', smoke)
        self.assertIn("MARCADOR_A := 0x31", smoke)
        self.assertIn("MARCADOR_B := 0x42", smoke)
        self.assertIn("save_a == save_b", smoke)
        self.assertIn("reabrir la portátil no restauró la SRAM", smoke)
        self.assertIn("guardar la ROM B modificó la SRAM de la ROM A", smoke)
        self.assertIn("MARCADOR_SRAM", fixture)
        self.assertIn("RGBFIX_CARTUCHO := -m 0x1B -r 0x02 -p 255 -v", makefile)

    def test_alpha_importa_antes_del_smoke(self):
        importar = "godot4 --headless --editor --path godot --quit"
        smoke = "godot4 --headless --path godot --script res://pruebas/emulador_gb_smoke.gd"
        self.assertIn(importar, self.alpha)
        self.assertIn(smoke, self.alpha)
        self.assertLess(self.alpha.index(importar), self.alpha.index(smoke))


if __name__ == "__main__":
    unittest.main()
