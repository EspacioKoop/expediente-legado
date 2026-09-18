from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
LINK = ROOT / "godot" / "guion" / "link_cable_portatil.gd"
AUDIO_UI = ROOT / "godot" / "guion" / "emulador_portatil_audio_app.gd"
CONSOLA = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
BASE_UI = ROOT / "godot" / "guion" / "emulador_portatil_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "emulador_gb_textos.json"
DOCS = ROOT / "docs" / "emulador-gb.md"


class EmuladorGBLinkCableTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.link = LINK.read_text(encoding="utf-8")
        cls.audio_ui = AUDIO_UI.read_text(encoding="utf-8")
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.base_ui = BASE_UI.read_text(encoding="utf-8")
        cls.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        cls.docs = DOCS.read_text(encoding="utf-8")

    def test_estado_es_local_independiente_del_nucleo(self):
        self.assertIn("class_name LinkCablePortatil", self.link)
        self.assertIn("extends RefCounted", self.link)
        self.assertIn("signal estado_cambiado(conectado: bool)", self.link)
        self.assertIn("func conectar() -> void:", self.link)
        self.assertIn("func desconectar() -> void:", self.link)
        self.assertIn("func alternar() -> bool:", self.link)
        for termino in (
            "Siga98GB",
            "Partida",
            "Jornada",
            "PacketPeer",
            "ENet",
            "HTTP",
            "TCP",
        ):
            self.assertNotIn(termino, self.link)

    def test_consola_lo_representa_y_comparte_con_la_ui(self):
        self.assertIn("var _link_cable := LinkCablePortatil.new()", self.consola)
        self.assertIn('cable.name = "CableLinkPortatil"', self.consola)
        self.assertIn("CylinderMesh.new()", self.consola)
        self.assertIn('name = "ConectorLinkCable"', self.consola)
        self.assertIn("_app.link_cable = _link_cable", self.consola)
        self.assertIn("_actualizar_link_cable_3d(conectado)", self.consola)

    def test_ui_conecta_sin_hablar_con_emulador(self):
        self.assertIn("var link_cable: LinkCablePortatil = null", self.audio_ui)
        self.assertIn('name = "PanelLinkCablePortatil"', self.audio_ui)
        self.assertIn('name = "EstadoLinkCablePortatil"', self.audio_ui)
        self.assertIn('name = "BotonLinkCablePortatil"', self.audio_ui)
        cuerpo = self.audio_ui.split("func _alternar_link_cable() -> void:", 1)[1].split(
            "func ", 1
        )[0]
        self.assertIn("link_cable.alternar()", cuerpo)
        self.assertIn('_reproducir_sonido_fisico(&"cable")', cuerpo)
        self.assertNotIn("_emulador", cuerpo)
        self.assertIn('&"cable": _crear_sonido_fisico', self.base_ui)

    def test_estado_visible_explica_el_limite_del_primer_corte(self):
        self.assertEqual(
            self.textos["link_cable_esperando"],
            "Link Cable conectado · esperando otra consola",
        )
        self.assertIn("no emula el puerto serie", self.textos["link_cable_aviso"])
        self.assertIn("Link Cable diegético (#245)", self.docs)
        self.assertIn("no hay networking", self.docs.lower())

    def test_no_se_convierte_en_progreso_de_campana(self):
        combinado = self.link + self.audio_ui
        for termino in ("Partida", "Jornada", "pistas_descubiertas", "dinero"):
            self.assertNotIn(termino, combinado)


if __name__ == "__main__":
    unittest.main()
