from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "godot" / "guion" / "bingo_siga_panel.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


def sin_comentarios(fuente):
    return "\n".join(linea.split("#", 1)[0] for linea in fuente.splitlines())


class BingoSigaUiTest(unittest.TestCase):
    def setUp(self):
        self.panel = PANEL.read_text(encoding="utf-8")
        self.controller = CONTROLLER.read_text(encoding="utf-8")
        self.textos = TEXTOS.read_text(encoding="utf-8")

    def test_panel_consume_el_estado_canonico(self):
        self.assertIn("class_name BingoSigaPanel", self.panel)
        self.assertIn("BingoSiga.tarjeta_diaria(_estado_partida)", self.panel)
        self.assertIn("BingoSiga.estado_tarjeta(_estado_partida)", self.panel)
        self.assertIn("BingoSiga.decidir(_estado_partida, decision)", self.panel)

    def test_tres_decisiones_explicitas(self):
        self.assertIn("BingoSiga.DECISION_ACEPTAR", self.panel)
        self.assertIn("BingoSiga.DECISION_DESCARTAR", self.panel)
        self.assertIn("BingoSiga.DECISION_IGNORAR", self.panel)
        for clave in (
            "BINGO_SIGA_ACEPTAR,",
            "BINGO_SIGA_DESCARTAR,",
            "BINGO_SIGA_IGNORAR,",
        ):
            self.assertIn(clave, self.textos)

    def test_es_una_app_del_shell_sin_guardado_paralelo(self):
        self.assertIn('"bingo-siga"', self.controller)
        self.assertIn('Callable(self, "_crear_bingo_siga")', self.controller)
        self.assertIn("_bingo_app.registrar_en(escritorio)", self.controller)
        bloque = self.controller[
            self.controller.index('_bingo_app = ('):
            self.controller.index("# Reponer el estado declarado", self.controller.index('_bingo_app = ('))
        ]
        self.assertNotIn("persistir_estado = true", bloque)

    def test_tarjeta_pendiente_se_materializa_sin_autoabrirse(self):
        self.assertIn("_preparar_bingo_diario(dia)", self.controller)
        self.assertIn("BingoSiga.tarjeta_diaria((partida_actual as Partida).estado)", self.controller)
        self.assertNotIn("_bingo_app.abrir(escritorio)", self.controller)
        self.assertIn('dia.call("_guardar_o_avisar", "")', self.controller)
        self.assertIn("(partida_actual as Partida).guardar()", self.controller)

    def test_ui_no_concede_recompensas(self):
        codigo = sin_comentarios(self.panel + "\n" + self.controller)
        for prohibido in (
            "Sellos.registrar_sello",
            "Jornada.gastar_accion",
            '["dinero"] +=',
            '["acciones"] +=',
            "pistas_descubiertas.append",
        ):
            self.assertNotIn(prohibido, codigo)

    def test_textos_principales_estan_localizados(self):
        for clave in (
            "BINGO_SIGA_APP_TITULO,",
            "BINGO_SIGA_CABECERA,",
            "BINGO_SIGA_AYUDA,",
            "BINGO_SIGA_DECISION,",
            "BINGO_SIGA_DECISION_PENDIENTE,",
            "BINGO_SIGA_DECISION_ACEPTADA,",
            "BINGO_SIGA_DECISION_DESCARTADA,",
            "BINGO_SIGA_DECISION_IGNORADA,",
        ):
            self.assertIn(clave, self.textos)


if __name__ == "__main__":
    unittest.main()
