import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
INDICE = ROOT / "godot" / "datos" / "roms_propias.json"
CONSOLA = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
VIGILIA = ROOT / "godot" / "guion" / "ryu_flow_vigilia.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
ROM_SOURCE = ROOT / "gbc" / "minijuegos" / "ryu_flow_98" / "main.asm"
DOCS = ROOT / "docs" / "roms-propias.md"


class RyuRuntimeSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        datos = json.loads(INDICE.read_text(encoding="utf-8"))
        cls.ryu = next(rom for rom in datos["roms"] if rom["id"] == "ryu_flow_98")
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.rom_source = ROM_SOURCE.read_text(encoding="utf-8")
        cls.docs = DOCS.read_text(encoding="utf-8")

    def test_ryu_flow_entra_en_build_y_consola_sin_compra(self):
        self.assertEqual(self.ryu["estado"], "jugable")
        self.assertEqual(self.ryu["rom"], "res://roms/ryu_flow_98.gbc")
        self.assertEqual(self.ryu["cabecera"], "RYUFLOW98")
        self.assertEqual(self.ryu["cgb"], "dual")
        self.assertTrue(self.ryu["incluida"])
        self.assertEqual(self.ryu["precio"], 0)

    def test_consola_expone_titulo_y_lectura_genericos(self):
        self.assertIn("func titulo_rom_activa() -> String:", self.consola)
        self.assertIn("func leer_memoria_rom_u8(direccion: int) -> int:", self.consola)
        self.assertIn('emulador.call("rom_title")', self.consola)
        self.assertIn('emulador.call("read_memory_u8", direccion)', self.consola)
        self.assertIn("return -1", self.consola)

    def test_superficie_generica_no_conoce_handshake_ryu(self):
        for termino in (
            "RYUFLOW98",
            "ryu_flow_98",
            "0xC100",
            "0xA5",
            "SemillasOniricas",
        ):
            self.assertNotIn(termino, self.consola)

    def test_observer_exige_rom_y_marca_de_victoria(self):
        self.assertIn('const TITULO_ROM := "RYUFLOW98"', self.vigilia)
        self.assertIn("const DIRECCION_COMPLETADO := 0xC100", self.vigilia)
        self.assertIn("const MARCA_COMPLETADO := 0xA5", self.vigilia)
        self.assertIn("_consola.titulo_rom_activa() != TITULO_ROM", self.vigilia)
        self.assertIn(
            "_consola.leer_memoria_rom_u8(DIRECCION_COMPLETADO) != MARCA_COMPLETADO",
            self.vigilia,
        )

    def test_observer_registra_con_contrato_comun_y_fuente_del_indice(self):
        self.assertIn('const ID_ROM := "ryu_flow_98"', self.vigilia)
        self.assertIn('const ID_MITO := "dragon_japones"', self.vigilia)
        self.assertIn("RomsPropias.fuente_semilla(ID_ROM)", self.vigilia)
        self.assertIn("SemillasOniricas.activar_semilla_onirica(", self.vigilia)
        self.assertIn("INTENSIDAD_SEMILLA", self.vigilia)

    def test_observer_funciona_mientras_el_emulador_pausa_el_mundo(self):
        self.assertIn("process_mode = Node.PROCESS_MODE_ALWAYS", self.vigilia)
        self.assertIn("set_process(true)", self.vigilia)
        self.assertIn("set_process(false)", self.vigilia)

    def test_casa_real_monta_el_observer_sobre_la_portatil_existente(self):
        self.assertIn('elif fase == "casa":', self.dia)
        self.assertIn("CasaUtileria.montar(_mundo)", self.dia)
        self.assertIn("_montar_ryu_flow_vigilia()", self.dia)
        self.assertIn('get_node_or_null("ConsolaPortatil98")', self.dia)
        self.assertIn("RyuFlowVigilia.new()", self.dia)
        self.assertIn("observador.configurar(jornada, consola)", self.dia)

    def test_rom_no_marca_completado_al_arrancar_ni_al_reiniciar(self):
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.rom_source)
        self.assertIn("DEF MARCA_COMPLETADO     EQU $A5", self.rom_source)

        inicio = self.rom_source.split("Inicio:", 1)[1].split("Bucle:", 1)[0]
        self.assertIn("xor a", inicio)
        self.assertIn("ld [wRyuFlowCompletado], a", inicio)

        reinicio = self.rom_source.split("IniciarJuego:", 1)[1].split(
            "SeleccionarAnterior:", 1
        )[0]
        self.assertIn("xor a", reinicio)
        self.assertIn("ld [wRyuFlowCompletado], a", reinicio)

        completar = self.rom_source.split("CompletarFlujo:", 1)[1].split(
            "DesactivarLCD:", 1
        )[0]
        self.assertIn("ld a, MARCA_COMPLETADO", completar)
        self.assertIn("ld [wRyuFlowCompletado], a", completar)

    def test_documentacion_refleja_promocion_y_handshake_conectado(self):
        self.assertIn("| `ryu_flow_98` | RYU FLOW |", self.docs)
        self.assertIn("incluida con la consola", self.docs)
        self.assertIn("`0xA5` en WRAM `$C100`", self.docs)
        self.assertIn("`RyuFlowVigilia`", self.docs)
        self.assertIn("registra `dragon_japones`", self.docs)


if __name__ == "__main__":
    unittest.main()
