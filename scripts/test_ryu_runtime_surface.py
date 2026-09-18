import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
INDICE = ROOT / "godot" / "datos" / "roms_propias.json"
CONSOLA = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
VIGILIA = ROOT / "godot" / "guion" / "ryu_flow_vigilia.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "semilla_rom_vigilia.gd"
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
        cls.adaptador = ADAPTADOR.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.rom_source = ROM_SOURCE.read_text(encoding="utf-8")
        cls.docs = DOCS.read_text(encoding="utf-8")

    def test_ryu_flow_entra_en_build_y_respeta_contrato_de_tienda(self):
        self.assertEqual(self.ryu["estado"], "jugable")
        self.assertEqual(self.ryu["rom"], "res://roms/ryu_flow_98.gbc")
        self.assertEqual(self.ryu["cabecera"], "RYUFLOW98")
        self.assertEqual(self.ryu["cgb"], "dual")
        self.assertFalse(self.ryu["incluida"])
        self.assertEqual(self.ryu["precio"], 45)

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
            "dragon_japones",
        ):
            self.assertNotIn(termino, self.consola)
            self.assertNotIn(termino, self.adaptador)

    def test_fachada_declara_rom_y_marca_de_victoria(self):
        self.assertIn('extends "res://guion/semilla_rom_vigilia.gd"', self.vigilia)
        self.assertIn('const TITULO_ROM := "RYUFLOW98"', self.vigilia)
        self.assertIn("const DIRECCION_COMPLETADO := 0xC100", self.vigilia)
        self.assertIn("const MARCA_COMPLETADO := 0xA5", self.vigilia)
        self.assertIn('"titulo_rom": TITULO_ROM', self.vigilia)
        self.assertIn('"direccion": DIRECCION_COMPLETADO', self.vigilia)
        self.assertIn('"valor": MARCA_COMPLETADO', self.vigilia)

    def test_fachada_delega_registro_al_contrato_comun(self):
        self.assertIn('const ID_ROM := "ryu_flow_98"', self.vigilia)
        self.assertIn('const ID_MITO := "dragon_japones"', self.vigilia)
        self.assertIn('"id_rom": ID_ROM', self.vigilia)
        self.assertIn('"id_mito": ID_MITO', self.vigilia)
        self.assertIn('"intensidad": INTENSIDAD_SEMILLA', self.vigilia)
        self.assertIn("configurar_contrato(", self.vigilia)
        self.assertIn("RomsPropias.fuente_semilla(id_rom)", self.adaptador)
        self.assertRegex(
            self.adaptador,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )

    def test_observer_comun_funciona_mientras_emulador_pausa_mundo(self):
        self.assertIn("process_mode = Node.PROCESS_MODE_ALWAYS", self.adaptador)
        self.assertIn("set_process(_contrato_valido())", self.adaptador)
        self.assertIn("set_process(false)", self.adaptador)

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
        self.assertIn("| `ryu_flow_98` | River of the Dragon |", self.docs)
        self.assertIn("tienda de videojuegos | 45", self.docs)
        self.assertIn("`0xA5` en WRAM `$C100`", self.docs)
        self.assertIn("`RyuFlowVigilia`", self.docs)
        self.assertIn("registra `dragon_japones`", self.docs)


if __name__ == "__main__":
    unittest.main()
