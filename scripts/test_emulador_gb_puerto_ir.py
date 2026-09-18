from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
IR = ROOT / "godot" / "guion" / "puerto_ir_portatil.gd"
AUDIO_UI = ROOT / "godot" / "guion" / "emulador_portatil_audio_app.gd"
CONSOLA = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
TEXTOS = ROOT / "godot" / "datos" / "emulador_gb_textos.json"
DOCS = ROOT / "docs" / "emulador-gb.md"


class EmuladorGBPuertoIRTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ir = IR.read_text(encoding="utf-8")
        cls.audio_ui = AUDIO_UI.read_text(encoding="utf-8")
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        cls.docs = DOCS.read_text(encoding="utf-8")

    def test_modulo_ir_es_local_y_no_emula_protocolo(self):
        self.assertIn("class_name PuertoIRPortatil", self.ir)
        self.assertIn("extends RefCounted", self.ir)
        self.assertIn("signal pulso_emitido(secuencia: int)", self.ir)
        self.assertIn("func emitir_pulso() -> int:", self.ir)
        self.assertIn("_pulsos_emitidos += 1", self.ir)
        for termino in (
            "Siga98GB",
            "Partida",
            "Jornada",
            "PacketPeer",
            "ENet",
            "HTTP",
            "TCP",
        ):
            self.assertNotIn(termino, self.ir)

    def test_carcasa_tiene_lente_y_destello_local(self):
        self.assertIn("var _puerto_ir := PuertoIRPortatil.new()", self.consola)
        self.assertIn('lente.name = "LenteIRPortatil"', self.consola)
        self.assertIn("SphereMesh.new()", self.consola)
        self.assertIn("_material_ir.emission_energy_multiplier = 1.8", self.consola)
        self.assertIn("create_timer(0.12, true)", self.consola)
        self.assertIn('_app.set("puerto_ir", _puerto_ir)', self.consola)

    def test_ui_emite_sin_hablar_con_nucleo(self):
        self.assertIn("var puerto_ir: PuertoIRPortatil = null", self.audio_ui)
        self.assertIn('name = "PanelPuertoIRPortatil"', self.audio_ui)
        self.assertIn('name = "EstadoPuertoIRPortatil"', self.audio_ui)
        self.assertIn('name = "BotonPuertoIRPortatil"', self.audio_ui)
        cuerpo = self.audio_ui.split("func _emitir_pulso_ir() -> void:", 1)[1].split(
            "func ", 1
        )[0]
        self.assertIn("puerto_ir.emitir_pulso()", cuerpo)
        self.assertNotIn("_emulador", cuerpo)

    def test_textos_declaran_que_es_ambiental_y_sin_protocolo(self):
        self.assertEqual(self.textos["ir_listo"], "IR listo · sin receptor local")
        self.assertIn("sin receptor", self.textos["ir_pulso_emitido"])
        self.assertIn("no emula el protocolo IR", self.textos["ir_aviso"])
        self.assertIn("Puerto IR ambiental/local (#245)", self.docs)
        self.assertIn("deliberadamente visual/ambiental", self.docs)

    def test_ir_no_se_convierte_en_progreso_de_campana(self):
        combinado = self.ir + self.audio_ui
        for termino in ("Partida", "Jornada", "pistas_descubiertas", "dinero"):
            self.assertNotIn(termino, combinado)


if __name__ == "__main__":
    unittest.main()
