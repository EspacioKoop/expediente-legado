from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
IMPRESORA = ROOT / "godot" / "guion" / "impresora_termica_portatil.gd"
FISICA = ROOT / "godot" / "guion" / "impresora_termica_portatil_3d.gd"
AUDIO_UI = ROOT / "godot" / "guion" / "emulador_portatil_audio_app.gd"
CONSOLA = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
UTILERIA = ROOT / "godot" / "guion" / "casa_utileria.gd"
TEXTOS = ROOT / "godot" / "datos" / "emulador_gb_textos.json"
DOCS = ROOT / "docs" / "emulador-gb.md"


class EmuladorGBImpresoraTermicaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.impresora = IMPRESORA.read_text(encoding="utf-8")
        cls.fisica = FISICA.read_text(encoding="utf-8")
        cls.audio_ui = AUDIO_UI.read_text(encoding="utf-8")
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        cls.docs = DOCS.read_text(encoding="utf-8")

    def test_estado_y_cola_son_locales(self):
        self.assertIn("class_name ImpresoraTermicaPortatil", self.impresora)
        self.assertIn("extends RefCounted", self.impresora)
        for estado in ("APAGADA", "LISTA", "IMPRIMIENDO", "PAPEL_DISPONIBLE"):
            self.assertIn(estado, self.impresora)
        self.assertIn("var _cola: Array[Image] = []", self.impresora)
        self.assertIn("func encender() -> void:", self.impresora)
        self.assertIn("func apagar() -> void:", self.impresora)
        self.assertIn("func avanzar(delta: float) -> void:", self.impresora)
        self.assertIn("func recoger_papel() -> Image:", self.impresora)

    def test_acepta_imagen_y_framebuffer_explicito_sin_protocolo_real(self):
        self.assertIn("func encolar_imagen(imagen: Image) -> bool:", self.impresora)
        self.assertIn(
            "func aceptar_framebuffer_rgba(datos: PackedByteArray, ancho: int, alto: int) -> bool:",
            self.impresora,
        )
        self.assertIn("Image.create_from_data", self.impresora)
        self.assertIn("static func crear_patron_prueba() -> Image:", self.impresora)
        self.assertIn("TRAMA_4X4", self.impresora)
        self.assertNotIn("Game Boy Printer", self.impresora)
        self.assertNotIn("GB_", self.impresora)

    def test_no_conoce_campana_red_recompensas_ni_guardado(self):
        combinado = self.impresora + self.fisica
        for termino in (
            "Partida",
            "Jornada",
            "pistas_descubiertas",
            "dinero",
            "Inventario",
            "user://",
            "PacketPeer",
            "ENet",
            "HTTP",
            "TCP",
        ):
            self.assertNotIn(termino, combinado)

    def test_objeto_fisico_se_monta_junto_a_la_portatil_y_comparte_controlador(self):
        self.assertIn("class_name ImpresoraTermicaPortatil3D", self.fisica)
        self.assertIn("extends Interactuable3D", self.fisica)
        self.assertIn('name = "TiraPapelTermico"', self.fisica)
        self.assertIn('name = "LedImpresoraTermica"', self.fisica)
        self.assertIn("ImageTexture.create_from_image(imagen)", self.fisica)
        self.assertIn("ImpresoraTermicaPortatil3D.new()", self.utileria)
        self.assertIn('impresora.name = "ImpresoraTermicaPortatil"', self.utileria)
        self.assertIn("portatil.establecer_impresora_termica(impresora.controlador())", self.utileria)
        self.assertIn('_app.set("impresora_termica", _impresora_termica)', self.consola)

    def test_sonido_y_animacion_son_procedurales_y_desactivables(self):
        self.assertIn("AudioStreamWAV.new()", self.fisica)
        self.assertIn("datos.encode_s16(indice * 2, muestra)", self.fisica)
        self.assertIn("func establecer_sonido_habilitado(habilitado: bool)", self.fisica)
        self.assertIn("func establecer_animacion_habilitada(habilitada: bool)", self.fisica)
        for termino in ("load(", "preload(", ".wav", ".ogg", ".mp3"):
            self.assertNotIn(termino, self.fisica)

    def test_ui_imprime_solo_patron_propio_y_no_lee_el_nucleo(self):
        self.assertIn("var impresora_termica: ImpresoraTermicaPortatil = null", self.audio_ui)
        self.assertIn('name = "PanelImpresoraTermica"', self.audio_ui)
        self.assertIn('name = "BotonImpresoraTermica"', self.audio_ui)
        cuerpo = self.audio_ui.split("func _usar_impresora_termica() -> void:", 1)[1].split(
            "func ", 1
        )[0]
        self.assertIn("ImpresoraTermicaPortatil.crear_patron_prueba()", cuerpo)
        self.assertNotIn("_emulador", cuerpo)
        self.assertNotIn("run_frame_rgba", cuerpo)
        self.assertIn("impresora_aviso", self.textos)

    def test_documentacion_declara_el_limite_del_primer_corte(self):
        self.assertIn("Impresora térmica diegética (#1054)", self.docs)
        self.assertIn("patrón procedural propio", self.docs)
        self.assertIn("no implementa el protocolo", self.docs.lower())
        self.assertIn("sin recompensas", self.docs.lower())


if __name__ == "__main__":
    unittest.main()
