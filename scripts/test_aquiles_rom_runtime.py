import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
INDICE = ROOT / "godot" / "datos" / "roms_propias.json"
CONSOLA = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
VIGILIA = ROOT / "godot" / "guion" / "aquiles_98_vigilia.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "semilla_rom_vigilia.gd"
DIA_AQUILES = ROOT / "godot" / "guion" / "dia_aquiles_vigilia_app.gd"
ROM_SOURCE = ROOT / "gbc" / "minijuegos" / "aquiles_98" / "game.asm"
README = ROOT / "gbc" / "minijuegos" / "aquiles_98" / "README.md"


class AquilesRomRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        datos = json.loads(INDICE.read_text(encoding="utf-8"))
        cls.aquiles = next(rom for rom in datos["roms"] if rom["id"] == "aquiles_98")
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.adaptador = ADAPTADOR.read_text(encoding="utf-8")
        cls.dia = DIA_AQUILES.read_text(encoding="utf-8")
        cls.rom_source = ROM_SOURCE.read_text(encoding="utf-8")
        cls.readme = README.read_text(encoding="utf-8")

    def test_myrmidon_sigue_en_catalogo_jugable(self):
        self.assertEqual(self.aquiles["estado"], "jugable")
        self.assertEqual(self.aquiles["rom"], "res://roms/aquiles_98.gbc")
        self.assertEqual(self.aquiles["cabecera"], "MYRMIDON98")
        self.assertEqual(self.aquiles["cgb"], "dual")
        self.assertFalse(self.aquiles["incluida"])
        self.assertEqual(self.aquiles["precio"], 45)

    def test_consola_permanece_generica(self):
        self.assertIn("func titulo_rom_activa() -> String:", self.consola)
        self.assertIn("func leer_memoria_rom_u8(direccion: int) -> int:", self.consola)
        for termino in (
            "MYRMIDON98",
            "aquiles_98",
            "Aquiles98Vigilia",
            "0xC000",
            "ESTADO_VICTORIA",
        ):
            self.assertNotIn(termino, self.consola)
            self.assertNotIn(termino, self.adaptador)

    def test_rom_expone_victoria_estable_en_primer_byte_wram(self):
        self.assertEqual(self.rom_source.count("WRAM0"), 1)
        estado = self.rom_source.split('SECTION "Estado", WRAM0', 1)[1].lstrip()
        self.assertTrue(estado.startswith("wEstado:"), estado[:80])
        self.assertIn("DEF ESTADO_VICTORIA EQU 2", self.rom_source)

        victoria = self.rom_source.split("MostrarVictoria:", 1)[1].split(
            "DesactivarLCD:", 1
        )[0]
        self.assertIn("ld a, ESTADO_VICTORIA", victoria)
        self.assertIn("ld [wEstado], a", victoria)

        reinicio = self.rom_source.split("IniciarDuelo:", 1)[1].split(
            "MoverMira:", 1
        )[0]
        self.assertIn("ld a, ESTADO_DUELO", reinicio)
        self.assertIn("ld [wEstado], a", reinicio)

    def test_fachada_declara_rom_y_estado_de_victoria(self):
        self.assertIn('extends "res://guion/semilla_rom_vigilia.gd"', self.vigilia)
        self.assertIn('const TITULO_ROM := "MYRMIDON98"', self.vigilia)
        self.assertIn("const DIRECCION_ESTADO := 0xC000", self.vigilia)
        self.assertIn("const ESTADO_VICTORIA := 2", self.vigilia)
        self.assertIn('"titulo_rom": TITULO_ROM', self.vigilia)
        self.assertIn('"direccion": DIRECCION_ESTADO', self.vigilia)
        self.assertIn('"valor": ESTADO_VICTORIA', self.vigilia)

    def test_fachada_delega_registro_al_contrato_comun(self):
        self.assertIn('const ID_ROM := "aquiles_98"', self.vigilia)
        self.assertIn('const ID_MITO := "aquiles"', self.vigilia)
        self.assertIn('"id_rom": ID_ROM', self.vigilia)
        self.assertIn('"id_mito": ID_MITO', self.vigilia)
        self.assertIn('"intensidad": INTENSIDAD_SEMILLA', self.vigilia)
        self.assertIn("configurar_contrato(", self.vigilia)
        self.assertIn("RomsPropias.fuente_semilla(id_rom)", self.adaptador)
        self.assertIn(
            "SemillasOniricas.activar_semilla_onirica(",
            self.adaptador,
        )

    def test_observer_comun_sigue_activo_con_arbol_pausado(self):
        self.assertIn("process_mode = Node.PROCESS_MODE_ALWAYS", self.adaptador)
        self.assertIn("set_process(_contrato_valido())", self.adaptador)
        self.assertIn("set_process(false)", self.adaptador)

    def test_controller_domestico_monta_observer_sin_duplicarlo(self):
        self.assertIn('get_node_or_null("ConsolaPortatil98")', self.dia)
        self.assertIn("Aquiles98Vigilia.new()", self.dia)
        self.assertIn("observador.configurar(jornada, consola)", self.dia)
        self.assertIn("_rom_observador_mundo_id", self.dia)
        self.assertIn('fase", "")) != "casa"', self.dia)

    def test_documentacion_declara_trigger_deliberado(self):
        self.assertIn("Aquiles98Vigilia", self.readme)
        self.assertIn("$C000", self.readme)
        self.assertIn("comprar", self.readme.lower())
        self.assertIn("arrancar", self.readme.lower())
        self.assertIn("victoria", self.readme.lower())


if __name__ == "__main__":
    unittest.main()
