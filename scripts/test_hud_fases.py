import json
from pathlib import Path
import unittest

from scripts.godot_pruebas import ejecutar_script


RAIZ = Path(__file__).resolve().parents[1]
CONTROLADOR = RAIZ / "godot" / "guion" / "dia_hud_fases_app.gd"
HUD_LAYER = RAIZ / "godot" / "guion" / "hud_layer.gd"
TEXTOS_RECURSOS = RAIZ / "godot" / "datos" / "hud_recursos_textos.json"
ESCENA = RAIZ / "godot" / "escenas" / "dia.tscn"


class HudFasesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.hud_layer = HUD_LAYER.read_text(encoding="utf-8")
        cls.textos_recursos = json.loads(TEXTOS_RECURSOS.read_text(encoding="utf-8"))
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_contrato_recursos_ejecutable_en_godot(self):
        resultado = ejecutar_script("res://pruebas/pruebas_hud_recursos_contextuales.gd")
        salida = (resultado.stdout or "") + (resultado.stderr or "")
        self.assertEqual(resultado.returncode, 0, salida)
        self.assertIn("hud_recursos:", resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)

    def test_estado_permanente_se_limita_al_archivo(self):
        cuerpo = self.controlador.split("func _sincronizar_estado_hud", 1)[1]
        self.assertIn('if fase == "archivo":', cuerpo)
        self.assertIn("hud.activar(HUDLayer.ESTADO)", cuerpo)
        self.assertIn("hud.desactivar(HUDLayer.ESTADO)", cuerpo)

    def test_cambiar_fase_no_apaga_el_arbitro_completo(self):
        cuerpo = self.controlador.split("func _sincronizar_estado_hud", 1)[1].split(
            "static func modelo_recursos", 1
        )[0]
        self.assertNotIn("visible = false", cuerpo)
        self.assertNotIn("INTERACCION", cuerpo)
        self.assertNotIn("DIALOGO", cuerpo)
        self.assertNotIn("MODAL", cuerpo)

    def test_tarjeta_identifica_las_cuatro_fases(self):
        for texto in (
            '"archivo": "ARCHIVO · PLANTA 4"',
            '"trayecto": "TRAYECTO"',
            '"casa": "CASA"',
            '"sueño": "SUEÑO"',
        ):
            self.assertIn(texto, self.controlador)

    def test_tarjeta_es_breve_y_desaparece_sola(self):
        self.assertIn("DURACION_TARJETA_FASE := 1.5", self.controlador)
        self.assertIn("_temporizador_fase.one_shot = true", self.controlador)
        self.assertIn("_temporizador_fase.timeout.connect(_ocultar_tarjeta_fase)", self.controlador)
        self.assertIn("hud.activar(HUDLayer.FASE)", self.controlador)
        self.assertIn("hud.desactivar(HUDLayer.FASE)", self.controlador)

    def test_tarjeta_no_se_consume_detras_de_cinematica(self):
        proceso = self.controlador.split("func _process", 1)[1].split(
            "func _sincronizar_estado_hud", 1
        )[0]
        self.assertIn("if not hud.visible:", proceso)
        self.assertLess(proceso.index("if not hud.visible:"), proceso.index("_fase_anterior = fase"))

    def test_recursos_se_refrescan_sin_necesitar_cambio_de_fase(self):
        proceso = self.controlador.split("func _process", 1)[1].split(
            "func _sincronizar_estado_hud", 1
        )[0]
        self.assertLess(
            proceso.index("_sincronizar_recursos"), proceso.index("if fase == _fase_anterior")
        )

    def test_recursos_comparten_arbitro_y_no_crean_otro_canvas(self):
        self.assertIn("const RECURSOS", self.hud_layer)
        self.assertIn(
            "hud.registrar(HUDLayer.RECURSOS, _recursos_panel)", self.controlador
        )
        self.assertNotIn("CanvasLayer.new()", self.controlador)

    def test_copy_de_recursos_vive_fuera_del_gdscript(self):
        for clave in (
            "dia",
            "hora",
            "acciones",
            "dinero",
            "pistas",
            "lecturas_gratis",
            "objetos_fuera",
            "objetos_casa",
            "alquiler_hoy",
        ):
            self.assertTrue(self.textos_recursos.get(clave), clave)
        self.assertNotIn('"ACCIONES %d"', self.controlador)
        self.assertNotIn('"DINERO %d"', self.controlador)

    def test_tarjeta_se_registra_en_arbitro_comun(self):
        self.assertIn("hud.add_child(_tarjeta_fase)", self.controlador)
        self.assertIn("hud.registrar(HUDLayer.FASE, _tarjeta_fase)", self.controlador)
        self.assertNotIn("CanvasLayer.new()", self.controlador)

    def test_la_escena_conserva_raiz_historica_y_anade_controller(self):
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)
        self.assertIn('path="res://guion/dia_hud_fases_app.gd" id="11"', self.escena)
        self.assertIn('[node name="HUDFasesController" type="Node" parent="."]', self.escena)
        self.assertIn('script = ExtResource("11")', self.escena)


if __name__ == "__main__":
    unittest.main()
