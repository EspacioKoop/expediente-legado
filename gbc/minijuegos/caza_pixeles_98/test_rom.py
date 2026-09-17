from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "main.asm"
ROM = ROOT / "build" / "caza_pixeles_98.gbc"


class CazaPixeles98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def bloque(self, inicio, fin):
        return self.source.split(inicio, 1)[1].split(fin, 1)[0]

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

    def test_campana_tiene_tres_fases_con_presentacion_distinta(self):
        self.assertIn("DEF SEGUNDOS_PARTIDA EQU 45", self.source)
        self.assertIn("DEF FASE2_TIEMPO     EQU 30", self.source)
        self.assertIn("DEF FASE3_TIEMPO     EQU 15", self.source)
        tick = self.bloque("TickTiempo:", "ActualizarOAM:")
        self.assertIn("ld a, 2\n    ld [wFase], a", tick)
        self.assertIn("ld a, 3\n    ld [wFase], a", tick)
        self.assertIn("call AplicarPaletaFase", tick)
        self.assertIn("PaletaFase2:", self.source)
        self.assertIn("PaletaFase3:", self.source)

    def test_tres_tipos_de_objetivo_cambian_reglas_y_sprite(self):
        self.assertIn("DEF TIPO_CROMA   EQU 0", self.source)
        self.assertIn("DEF TIPO_SEMILLA EQU 1", self.source)
        self.assertIn("DEF TIPO_FOCO    EQU 2", self.source)
        mover = self.bloque("MoverObjetivo:", "ComprobarCaptura:")
        self.assertIn("cp TIPO_FOCO\n    ret z", mover)
        self.assertIn("cp TIPO_SEMILLA", mover)
        oam = self.bloque("ActualizarOAM:", "ActualizarHUD:")
        self.assertIn("TILE_OBJETIVO", oam)
        self.assertIn("TILE_SEMILLA", oam)
        self.assertIn("TILE_FOCO", oam)

    def test_restaurar_compite_con_combo_y_modifica_estado(self):
        foco = self.bloque("CerrarFocoContaminante:", "SumarRestauracion:")
        self.assertIn("ld [wCombo], a", foco)
        self.assertIn("ld [wComboFrames], a", foco)
        self.assertIn("ld [wMultiplicador], a", foco)
        self.assertIn("wFocosCerrados", foco)
        self.assertIn("RESTAURA_FOCO", foco)
        semilla = self.bloque(".semilla:", ".foco:")
        self.assertIn("RESTAURA_SEMILLA", semilla)
        self.assertIn("call SumarRestauracion", semilla)

    def test_hud_expone_fase_restauracion_y_multiplicador(self):
        self.assertIn("ld hl, BG_MAP + 9", self.source)
        self.assertIn("ld a, TILE_X", self.source)
        actualizar = self.bloque("ActualizarHUD:", "DibujarTitulo:")
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
