from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parent
CINEMA = (ROOT / "cinematicas.asm").read_text(encoding="utf-8")


def bloque(inicio: str, fin: str) -> str:
    return CINEMA.split(inicio, 1)[1].split(fin, 1)[0]


def valor_def(nombre: str) -> int:
    match = re.search(rf"DEF {re.escape(nombre)}\s+EQU\s+(\d+)", CINEMA)
    if match is None:
        raise AssertionError(f"falta DEF {nombre}")
    return int(match.group(1))


class PixelExodusCierreTest(unittest.TestCase):
    def test_intro_es_instruccion_legible_antes_del_primer_segundo(self):
        self.assertEqual(valor_def("CIN_INTRO_FRAMES"), 72)
        self.assertGreaterEqual(valor_def("CIN_INSTRUCCIONES_FRAMES"), 120)
        inicio = bloque("IniciarCinematicaIntro:", "IniciarCinematicaFase2:")
        self.assertIn("CIN_INSTRUCCIONES_FRAMES", inicio)
        self.assertIn("TILE_CIN_CRUCETA", CINEMA)
        self.assertIn("TILE_CIN_FLECHA", CINEMA)

        intro = bloque(".intro:", ".fase2:")
        self.assertIn("call DibujarInstruccionesIntro", intro)

        instrucciones = bloque("DibujarInstruccionesIntro:", "LimpiarInstruccionesIntro:")
        for token in (
            "TILE_CIN_CRUCETA",
            "TILE_JUGADOR",
            "TILE_OBJETIVO",
            "TILE_SEMILLA",
            "TILE_FOCO",
            "TILE_R",
            "TILE_X",
        ):
            self.assertIn(token, instrucciones)

        pausa = bloque("BloquearGameplayInstrucciones:", "; Cinco viñetas")
        self.assertIn("wJugadorSeguroX", pausa)
        self.assertIn("wJugadorSeguroY", pausa)
        self.assertIn("wObjetivoTick", pausa)
        self.assertIn("wFrames", pausa)
        self.assertNotIn("wTiempo", pausa)

        tick = bloque("TickCinematica:", "; El onboarding sucede")
        self.assertLess(
            tick.index("call BloquearGameplayInstrucciones"),
            tick.index("call ResolverObstaculosGameplay"),
            "la posición segura debe resolverse después de rechazar la cruceta del onboarding",
        )

    def test_fases_dos_y_tres_tienen_barreras_bg_con_colision_real(self):
        self.assertEqual(valor_def("OBSTACULO_ANCHO"), 16)
        self.assertEqual(valor_def("OBSTACULO_ALTO"), 8)
        for nombre in (
            "OBSTACULO_1_X",
            "OBSTACULO_1_Y",
            "OBSTACULO_2_X",
            "OBSTACULO_2_Y",
            "OBSTACULO_3_X",
            "OBSTACULO_3_Y",
        ):
            self.assertGreater(valor_def(nombre), 0)

        dibujo = bloque("DibujarObstaculosGameplay:", "DibujarBarreraResiduo:")
        self.assertIn("cp 2", dibujo)
        self.assertIn("cp 3", dibujo)
        self.assertGreaterEqual(dibujo.count("call DibujarBarreraResiduo"), 3)

        resolver = bloque("ResolverObstaculosGameplay:", "JugadorChocaObstaculosActivos:")
        self.assertIn("call JugadorChocaObstaculosActivos", resolver)
        self.assertIn("wJugadorSeguroX", resolver)
        self.assertIn("wJugadorSeguroY", resolver)
        self.assertIn("ld a, 80", resolver)
        self.assertIn("ld a, 88", resolver)

        aabb = bloque("ColisionObstaculoBC:", "; Epilogo estatico")
        self.assertIn("OBSTACULO_ANCHO", aabb)
        self.assertIn("OBSTACULO_ALTO", aabb)
        self.assertIn("scf", aabb)

        # Los obstáculos son parte del tilemap y no elevan el presupuesto del boss.
        self.assertNotIn("OAM_BASE", CINEMA)
        self.assertIn("TILE_CIN_RESIDUO", CINEMA)

    def test_boss_retira_barreras_para_preservar_la_arena(self):
        dibujo = bloque("DibujarObstaculosGameplay:", "DibujarBarreraResiduo:")
        self.assertIn("wBossActivo", dibujo)
        self.assertIn("LimpiarObstaculosGameplay", dibujo)
        resolver = bloque("ResolverObstaculosGameplay:", "JugadorChocaObstaculosActivos:")
        self.assertIn("wBossActivo", resolver)

    def test_records_finales_usan_panel_limpio_y_paleta_de_texto(self):
        final = bloque("DibujarCinematicaFinal:", "LimpiarPanelRecords:")
        self.assertIn("call LimpiarPanelRecords", final)
        panel = bloque("LimpiarPanelRecords:", "CargarTilesCinematicas:")
        self.assertIn("BG_MAP + (3 * 32) + 2", panel)
        self.assertIn("ld b, 8", panel)
        self.assertIn("ld c, 16", panel)
        self.assertIn("call EsCGB", panel)
        self.assertIn("ldh [rVBK], a", panel)
        # XOR A escribe TILE_VACIO en banco 0 y atributo/paleta 0 en banco 1.
        self.assertGreaterEqual(panel.count("xor a"), 3)


if __name__ == "__main__":
    unittest.main()
