from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "main.asm"
SCENARIO = ROOT / "escenario.asm"
MAKEFILE = ROOT / "Makefile"
ROM = ROOT / "build" / "caza_pixeles_98.gbc"


class CazaPixeles98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")
        cls.scenario = SCENARIO.read_text(encoding="utf-8")
        cls.makefile = MAKEFILE.read_text(encoding="utf-8")

    def bloque(self, inicio, fin):
        return self.source.split(inicio, 1)[1].split(fin, 1)[0]

    def bloque_escenario(self, inicio, fin):
        return self.scenario.split(inicio, 1)[1].split(fin, 1)[0]

    def valor_def(self, nombre):
        match = re.search(rf"DEF {re.escape(nombre)}\s+EQU\s+(\d+)", self.source)
        self.assertIsNotNone(match, f"falta DEF {nombre}")
        return int(match.group(1))

    def valor_def_escenario(self, nombre):
        match = re.search(rf"DEF {re.escape(nombre)}\s+EQU\s+(\d+)", self.scenario)
        self.assertIsNotNone(match, f"falta DEF {nombre}")
        return int(match.group(1))

    def test_combo_tiene_ventana_tres_multiplicadores_y_record(self):
        self.assertIn("DEF COMBO_DURACION   EQU 90", self.source)
        self.assertIn("DEF COMBO_X2         EQU 3", self.source)
        self.assertIn("DEF COMBO_X3         EQU 6", self.source)
        bloque = self.bloque("RegistrarCaptura:", "CerrarFocoContaminante:")
        self.assertIn("wMejorComboPartida", bloque)
        self.assertIn("ld a, 99", bloque)

    def test_objetivos_usan_rng_y_no_repeticion_inmediata(self):
        self.assertIn("DEF rDIV", self.source)
        self.assertIn("AvanzarRng:", self.source)
        self.assertIn("xor $B8", self.source)
        bloque = self.bloque("SiguienteObjetivo:", "TickTiempo:")
        self.assertIn("call AvanzarRng", bloque)
        self.assertIn("cp b\n    jr nz, .indice_listo", bloque)

    def test_campana_tiene_tres_fases_y_final_de_boss(self):
        self.assertIn("DEF SEGUNDOS_PARTIDA EQU 45", self.source)
        self.assertIn("DEF FASE2_TIEMPO     EQU 30", self.source)
        self.assertIn("DEF FASE3_TIEMPO     EQU 15", self.source)
        self.assertIn("DEF FASE_FINAL       EQU 4", self.source)
        tick = self.bloque("TickTiempo:", "; -------------------------- Glitch Behemoth")
        self.assertIn("ld a, 2\n    ld [wFase], a", tick)
        self.assertIn("ld a, 3\n    ld [wFase], a", tick)
        self.assertIn("call IniciarBehemoth", tick)
        self.assertEqual(tick.count("call TransicionEscenarioFase"), 2)

    def test_tres_tipos_de_objetivo_cambian_reglas_y_sprite(self):
        self.assertIn("DEF TIPO_CROMA   EQU 0", self.source)
        self.assertIn("DEF TIPO_SEMILLA EQU 1", self.source)
        self.assertIn("DEF TIPO_FOCO    EQU 2", self.source)
        mover = self.bloque("MoverObjetivo:", "ComprobarCaptura:")
        self.assertIn("cp TIPO_FOCO\n    ret z", mover)
        self.assertIn("cp TIPO_SEMILLA", mover)
        oam = self.bloque("ActualizarOAM:", "; HL llega al segundo sprite OAM")
        self.assertIn("TILE_OBJETIVO", oam)
        self.assertIn("TILE_SEMILLA", oam)
        self.assertIn("TILE_FOCO", oam)

    def test_restaurar_compite_con_combo_y_modifica_estado(self):
        foco = self.bloque("CerrarFocoContaminante:", "; A = incremento de restauracion")
        self.assertIn("ld [wCombo], a", foco)
        self.assertIn("ld [wComboFrames], a", foco)
        self.assertIn("ld [wMultiplicador], a", foco)
        self.assertIn("wFocosCerrados", foco)
        self.assertIn("RESTAURA_FOCO", foco)
        semilla = self.bloque(".semilla:", ".foco:")
        self.assertIn("RESTAURA_SEMILLA", semilla)
        self.assertIn("call SumarRestauracion", semilla)

    def test_chromia_tiene_cuatro_estados_visuales_y_atributos_cgb(self):
        actualizar = self.bloque("ActualizarChromia:", "DibujarChromia:")
        self.assertIn("cp 75", actualizar)
        self.assertIn("cp 50", actualizar)
        self.assertIn("cp 25", actualizar)
        self.assertIn("wEtapaChromia", actualizar)
        self.assertIn("call ActualizarFaunaVisual", actualizar)
        self.assertIn("TILE_PLANETA_SECO", self.source)
        self.assertIn("TILE_PLANETA_AGUA", self.source)
        self.assertIn("TILE_PLANETA_BOSQUE", self.source)
        self.assertIn("TILE_PLANETA_VIVO", self.source)
        attrs = self.bloque("AplicarAtributosChromia:", "CargarPaletaPlaneta:")
        self.assertIn("ldh [rVBK], a", attrs)
        self.assertIn("ld d, 1", attrs)
        self.assertIn("PaletaPlanetaVivo:", self.source)

    def test_behemoth_aparece_en_ultimos_segundos_y_tiene_cuatro_nucleos(self):
        self.assertIn("DEF BEHEMOTH_TIEMPO  EQU 8", self.source)
        self.assertEqual(self.valor_def("BEHEMOTH_PUNTOS"), 4)
        self.assertIn("PuntosBehemoth:", self.source)
        self.assertIn("IniciarBehemoth:", self.source)
        self.assertIn("ComprobarPuntoBehemoth:", self.source)
        self.assertIn("call TransicionBehemothVisual", self.source)
        golpe = self.bloque("GolpearBehemoth:", "ActualizarOAM:")
        self.assertIn("cp BEHEMOTH_PUNTOS", golpe)
        self.assertIn("RESTAURA_NUCLEO", golpe)
        self.assertIn("RESTAURA_BOSS", golpe)
        self.assertIn("ld a, FASE_FINAL", golpe)

    def test_behemoth_es_metasprite_32x32_con_presupuesto_oam_seguro(self):
        self.assertEqual(self.valor_def("BOSS_SPRITES_CUERPO"), 16)
        self.assertEqual(self.valor_def("BOSS_SPRITES_LINEA"), 4)
        max_linea = self.valor_def("MAX_SPRITES_LINEA_BEHEMOTH")
        self.assertLessEqual(max_linea, 10)
        self.assertEqual(max_linea, 6)
        oam = self.bloque("DibujarBehemothOAM:", "; ---------------------------- HUD / Chromia")
        self.assertIn("ld e, 4", oam)
        self.assertIn("cp 4", oam)
        self.assertIn("TILE_BEHEMOTH_A", oam)
        self.assertIn("TILE_BEHEMOTH_B", oam)
        self.assertIn("TILE_NUCLEO", oam)

    def test_behemoth_tiene_cooldown_entre_puntos_y_final_diferenciado(self):
        self.assertIn("DEF BEHEMOTH_INVULN_FRAMES", self.source)
        tick = self.bloque("TickBehemoth:", "ActualizarPuntoBehemoth:")
        self.assertIn("wBossInvuln", tick)
        golpe = self.bloque("GolpearBehemoth:", "ActualizarOAM:")
        self.assertIn("BEHEMOTH_INVULN_FRAMES", golpe)
        self.assertIn("wBossDerrotado", golpe)
        final = self.bloque("DibujarResultadoBoss:", "DesactivarLCD:")
        self.assertIn("TILE_SEMILLA", final)
        self.assertIn("TILE_NUCLEO", final)

    def test_escenario_tiene_fondo_completo_por_fase_y_paleta_cgb_propia(self):
        self.assertIn('INCLUDE "escenario.asm"', self.source)
        self.assertIn("escenario.asm", self.makefile)
        self.assertIn("DibujarFondoFaseVisual:", self.scenario)
        self.assertIn("TILE_ESC_ATMOSFERA", self.scenario)
        self.assertIn("TILE_ESC_INDUSTRIA", self.scenario)
        self.assertIn("TILE_ESC_NEBULOSA", self.scenario)
        attrs = self.bloque_escenario(
            "AplicarAtributosEscenarioVisual:", "CargarPaletaEscenarioVisual:"
        )
        self.assertIn("ldh [rVBK], a", attrs)
        self.assertIn("ld a, 2 ; paleta BG 2", attrs)
        self.assertIn("PaletaEscenarioF1:", self.scenario)
        self.assertIn("PaletaEscenarioF2:", self.scenario)
        self.assertIn("PaletaEscenarioF3:", self.scenario)

    def test_parallax_tiene_dos_capas_con_velocidades_distintas_sin_scroll_global(self):
        rapido = self.valor_def_escenario("PARALLAX_RAPIDO_FRAMES")
        lento = self.valor_def_escenario("PARALLAX_LENTO_FRAMES")
        self.assertLess(rapido, lento)
        tick = self.bloque_escenario("TickParallaxVisual:", "MoverParallaxRapido:")
        self.assertIn("call MoverParallaxRapido", tick)
        self.assertIn("call MoverParallaxLento", tick)
        self.assertNotRegex(self.scenario, r"ldh\s+\[rSCX\]")
        self.assertNotRegex(self.scenario, r"ldh\s+\[rSCY\]")
        self.assertIn("BG_MAP + (4 * 32)", self.scenario)
        self.assertIn("BG_MAP + (8 * 32)", self.scenario)

    def test_fauna_es_bg_reactiva_a_restauracion_y_no_consume_oam(self):
        self.assertIn("TILE_ESC_AVE_A", self.scenario)
        self.assertIn("TILE_ESC_AVE_B", self.scenario)
        self.assertIn("TILE_ESC_PEZ_A", self.scenario)
        self.assertIn("TILE_ESC_PEZ_B", self.scenario)
        fauna = self.bloque_escenario("DibujarFaunaVisual:", "LimpiarFaunaVisual:")
        self.assertIn("wEtapaChromia", fauna)
        self.assertIn("cp 2", fauna)
        self.assertIn("cp 3", fauna)
        self.assertNotIn("OAM_BASE", self.scenario)
        self.assertNotIn("DibujarBehemothOAM", self.scenario)
        self.assertEqual(self.valor_def("MAX_SPRITES_LINEA_BEHEMOTH"), 6)

    def test_transiciones_son_breves_no_bloqueantes_y_no_tocan_timer(self):
        self.assertEqual(self.valor_def_escenario("TRANSICION_FRAMES"), 36)
        self.assertIn("IniciarTransicionVisual:", self.scenario)
        tick = self.bloque_escenario("TickTransicionVisual:", "DibujarBannerTransicionVisual:")
        self.assertIn("wTransicionFrames", tick)
        self.assertIn("call LimpiarBannerTransicionVisual", tick)
        transicion = self.bloque_escenario(
            "IniciarTransicionVisual:", "TickTransicionVisual:"
        )
        self.assertNotIn("halt", transicion)
        self.assertNotIn("wTiempo", transicion)
        self.assertIn("call DibujarEscenarioFinal", self.source)

    def test_hud_expone_fase_restauracion_y_multiplicador(self):
        self.assertIn("ld hl, BG_MAP + 9", self.source)
        self.assertIn("ld a, TILE_X", self.source)
        actualizar = self.bloque("ActualizarHUD:", "ActualizarChromia:")
        self.assertIn("wFase", actualizar)
        self.assertIn("wRestauracion", actualizar)
        self.assertIn("BG_MAP + 32 + 7", actualizar)

    def test_sram_guarda_records_con_magic_version_y_checksum(self):
        self.assertIn("DEF SRAM_MAGIC0", self.source)
        self.assertIn("DEF SRAM_MEJOR_PUNTOS", self.source)
        self.assertIn("DEF SRAM_MEJOR_COMBO", self.source)
        self.assertIn("DEF SRAM_MEJOR_FASE", self.source)
        self.assertIn("DEF SRAM_MEJOR_RESTAURACION", self.source)
        self.assertIn("CargarRecords:", self.source)
        self.assertIn("GuardarRecords:", self.source)
        self.assertIn("CalcularChecksumRecords:", self.source)
        escribir = self.bloque("EscribirRecords:", "CalcularChecksumRecords:")
        self.assertIn("ld a, $50", escribir)
        self.assertIn("ld a, $58", escribir)
        self.assertIn("ld a, $39", escribir)
        self.assertIn("ld a, $38", escribir)
        self.assertIn("call ProtegerSRAM", escribir)

    def test_dificultad_tolera_saltos_y_se_endurece_por_fase(self):
        bloque = self.bloque("AjustarDificultad:", "AvanzarRng:")
        self.assertIn("cp 3\n    jr z, .nivel3", bloque)
        self.assertIn("cp 2\n    jr z, .nivel2", bloque)
        self.assertIn("cp 20\n    jr nc, .nivel3", bloque)
        self.assertIn("cp 10\n    jr nc, .nivel2", bloque)
        self.assertIn("cp 5\n    ret c", bloque)

    def test_rom_compilada_conserva_cabecera_y_cartucho_con_sram(self):
        self.assertTrue(ROM.exists(), "falta compilar build/caza_pixeles_98.gbc")
        data = ROM.read_bytes()
        self.assertGreaterEqual(len(data), 32768)
        self.assertEqual(data[0x134:0x13F].rstrip(b"\0"), b"CAZAPIXEL98")
        self.assertEqual(data[0x143], 0x80)
        self.assertEqual(data[0x147], 0x1B, "debe ser MBC5+RAM+BATTERY")
        self.assertEqual(data[0x149], 0x02, "debe anunciar 8 KiB de SRAM")


if __name__ == "__main__":
    unittest.main()
