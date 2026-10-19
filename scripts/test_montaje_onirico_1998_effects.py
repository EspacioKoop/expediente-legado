"""Checks for the oniric montage opt-in effects (CRT, typographic overlay, non-stroboscopic grain, original audio cues).

These are structural regression checks, not a replacement for a visual playtest.
"""
from pathlib import Path
import json
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"
LENGUAJE = ROOT / "godot" / "guion" / "lenguaje_cine.gd"
SONIDO = ROOT / "godot" / "guion" / "sonido.gd"
CRT_SHADER = ROOT / "godot" / "arte" / "interrupcion_crt.gdshader"
SUP_SHADER = ROOT / "godot" / "arte" / "superposicion_tipografica.gdshader"
GRANO_SHADER = ROOT / "godot" / "arte" / "grano_cine.gdshader"


class MontajeOnirico1998EffectsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reproductor = REPRODUCTOR.read_text(encoding="utf-8")
        cls.lenguaje = LENGUAJE.read_text(encoding="utf-8")
        cls.sonido = SONIDO.read_text(encoding="utf-8")
        cls.crt_shader = CRT_SHADER.read_text(encoding="utf-8")
        cls.sup_shader = SUP_SHADER.read_text(encoding="utf-8")
        cls.grano_shader = GRANO_SHADER.read_text(encoding="utf-8")

    def test_crt_shader_exists_and_has_opt_in_params(self):
        for token in ("uniform float intensidad", "uniform float duracion", "uniform bool quieto", "scanline", "desincronia"):
            self.assertIn(token, self.crt_shader)
        self.assertIn("activo", self.crt_shader)
        self.assertIn("semilla", self.crt_shader)

    def test_superposicion_shader_exists_and_has_opt_in_params(self):
        for token in ("uniform sampler2D texto_textura", "uniform float intensidad", "uniform float ruido_amplitud", "uniform float scanline_fuerza", "uniform bool quieto"):
            self.assertIn(token, self.sup_shader)
        self.assertIn("semilla", self.sup_shader)

    def test_grano_shader_has_no_estroboscopico_mode(self):
        self.assertIn("uniform bool no_estroboscopico", self.grano_shader)
        self.assertIn("ruido_octavas", self.grano_shader)
        self.assertIn("no_estroboscopico", self.grano_shader)
        self.assertIn("ruido_octavas(FRAGCOORD.xy", self.grano_shader)

    def test_lenguaje_cine_has_new_constants(self):
        for const in ("CRT_INTENSIDAD_DEF", "CRT_DURACION_DEF", "SUP_INTENSIDAD_DEF", "SUP_RUIDO_DEF", "SUP_SCANLINE_DEF"):
            self.assertIn(const, self.lenguaje)
        self.assertIn("Grano no estroboscópico", self.lenguaje)
        self.assertIn("Interrupción CRT", self.lenguaje)
        self.assertIn("Superposición tipográfica", self.lenguaje)

    def test_reproductor_has_crt_and_superposicion_nodes(self):
        self.assertIn("_crt: ColorRect", self.reproductor)
        self.assertIn("_superposicion: ColorRect", self.reproductor)

        self.assertIn("_vista_superposicion: SubViewport", self.reproductor)
        self.assertIn("_etiqueta_superposicion: Label", self.reproductor)
        self.assertIn("interrupcion_crt.gdshader", self.reproductor)
        self.assertIn("superposicion_tipografica.gdshader", self.reproductor)
        self.assertIn("_configurar_efectos_plano", self.reproductor)
        self.assertIn("_actualizar_textura_superposicion", self.reproductor)

    def test_superposicion_mantiene_un_viewport_renderizable(self):
        self.assertIn("_vista_superposicion = SubViewport.new()", self.reproductor)
        self.assertIn("_vista_superposicion.render_target_update_mode = SubViewport.UPDATE_ALWAYS", self.reproductor)
        self.assertIn("_lienzo.add_child(_vista_superposicion)", self.reproductor)
        self.assertIn("_vista_superposicion.add_child(_etiqueta_superposicion)", self.reproductor)
        self.assertIn("_vista_superposicion.size = Vector2i(_lienzo.size)", self.reproductor)
        self.assertIn("_vista_superposicion.get_texture()", self.reproductor)

    def test_reproductor_configures_effects_per_shot(self):
        self.assertIn("interrupcion_crt", self.reproductor)
        self.assertIn("superposicion_texto", self.reproductor)
        self.assertIn("grano_no_estroboscopico", self.reproductor)
        self.assertIn("crt_intensidad", self.reproductor)
        self.assertIn("crt_duracion", self.reproductor)
        self.assertIn("sup_intensidad", self.reproductor)
        self.assertIn("sup_ruido", self.reproductor)
        self.assertIn("sup_scanline", self.reproductor)

    def test_reproductor_respects_reduccion_movimiento_for_new_effects(self):
        self.assertIn('_crt.material.set_shader_parameter("quieto", _reduccion_movimiento)', self.reproductor)
        self.assertIn('_superposicion.material.set_shader_parameter("quieto", _reduccion_movimiento)', self.reproductor)
        self.assertIn('mat_crt.set_shader_parameter("quieto", _reduccion_movimiento)', self.reproductor)
        self.assertIn('mat_sup.set_shader_parameter("quieto", _reduccion_movimiento)', self.reproductor)
        self.assertIn('mat_grano.set_shader_parameter("no_estroboscopico"', self.reproductor)

    def test_sonido_has_available_cc0_cues(self):
        self.assertIn("crt_interrupcion", self.sonido)
        self.assertIn("texto_superposicion", self.sonido)
        self.assertIn('"crt_interrupcion": "error_003.ogg"', self.sonido)
        self.assertNotIn('chip/crt_interrupcion_', self.sonido)
        self.assertIn('"texto_superposicion": "click_001.ogg"', self.sonido)
        self.assertNotIn('chip/texto_glitch_', self.sonido)
        self.assertIn("CATALOGO := {", self.sonido)
        self.assertIn("FAMILIAS := {", self.sonido)

    def test_sonido_uses_existing_catalog(self):
        self.assertIn('"crt_interrupcion": "error_003.ogg"', self.sonido)
        self.assertIn('"texto_superposicion": "click_001.ogg"', self.sonido)

    def test_reproductor_triggers_original_audio_cues(self):
        self.assertIn('Sonido.sonar(self, "crt_interrupcion"', self.reproductor)
        self.assertIn('Sonido.sonar(self, "texto_superposicion"', self.reproductor)

    def test_no_copyrighted_references_in_shaders(self):
        for forbidden in ("Lain", "Evangelion", "Paranoia Agent"):
            self.assertNotIn(forbidden, self.crt_shader)
            self.assertNotIn(forbidden, self.sup_shader)
            self.assertNotIn(forbidden, self.grano_shader)

    def test_audio_cues_have_cc0_provenance(self):
        manifest = ROOT / "godot" / "assets" / "procedencia.json"
        assets = {a["ruta"]: a for a in json.loads(manifest.read_text(encoding="utf-8"))["assets"]}
        for path in ("audio/error_003.ogg", "audio/click_001.ogg"):
            with self.subTest(path=path):
                self.assertIn(path, assets)
                self.assertEqual("CC0-1.0", assets[path]["licencia"])
                self.assertEqual("Kenney", assets[path]["autor"])



if __name__ == "__main__":
    unittest.main()