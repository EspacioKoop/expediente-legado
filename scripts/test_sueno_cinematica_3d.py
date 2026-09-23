from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CINEMATICA = ROOT / "godot" / "guion" / "sueno_cinematica.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_cinematica_sueno_controller.gd"
REACTIVO = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"
SONIDO = ROOT / "godot" / "guion" / "sonido.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class SuenoCinematica3DTest(unittest.TestCase):
    def setUp(self) -> None:
        self.cinematica = CINEMATICA.read_text(encoding="utf-8")
        self.controller = CONTROLLER.read_text(encoding="utf-8")
        self.reactivo = REACTIVO.read_text(encoding="utf-8")
        self.calle = CALLE.read_text(encoding="utf-8")
        self.reproductor = REPRODUCTOR.read_text(encoding="utf-8")
        self.sonido = SONIDO.read_text(encoding="utf-8")
        self.escena = ESCENA.read_text(encoding="utf-8")

    def test_transicion_es_3d_y_reutiliza_la_casa(self) -> None:
        self.assertEqual(self.cinematica.count('"tipo": "3d"'), 3)
        self.assertNotIn('"tipo": "2d"', self.cinematica)
        self.assertNotIn('"figura":', self.cinematica)
        self.assertEqual(self.cinematica.count('"camara": Vector3'), 3)
        self.assertEqual(self.cinematica.count('"mira": Vector3'), 3)
        self.assertEqual(self.cinematica.count('"camara_desde": Vector3'), 3)
        self.assertEqual(self.cinematica.count('"mira_desde": Vector3'), 3)
        self.assertIn("EspaciosCatalogo.CASA", self.cinematica)
        self.assertNotIn("MeshInstance3D", self.cinematica)
        self.assertNotIn("BoxMesh", self.cinematica)

    def test_post_playtest_tiene_accion_y_residuo_visual(self) -> None:
        self.assertIn('"nombre": "orientar-habitacion"', self.cinematica)
        self.assertIn('"nombre": "acostarse"', self.cinematica)
        self.assertIn('"nombre": "residuo-cama"', self.cinematica)
        self.assertIn('"fundido_desde": 0.0', self.cinematica)
        self.assertIn('"fundido_hasta": 0.92', self.cinematica)
        self.assertIn("func _actualizar_fundido(", self.reproductor)
        self.assertIn('plano.get("fundido_desde", 0.0)', self.reproductor)
        self.assertIn('plano.get("fundido_hasta", desde)', self.reproductor)
        self.assertIn("lerpf(desde, hasta, suave)", self.reproductor)
        self.assertIn(
            "_fundido.color = Color(0.0, 0.0, 0.0, 0.0)", self.reproductor
        )

    def test_acostarse_tiene_un_acento_fisico_sin_asset_nuevo(self) -> None:
        self.assertIn('"sonido": "cama"', self.cinematica)
        self.assertIn('"sonido_tono": 0.78', self.cinematica)
        self.assertIn('"cama": "impactSoft_medium_000.ogg"', self.sonido)
        self.assertIn("Sonido.sonar(self, nombre, tono)", self.reproductor)

    def test_controller_dedicado_no_cambia_la_cadena_historica(self) -> None:
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', self.calle)
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)
        self.assertIn(
            'path="res://guion/dia_cinematica_sueno_controller.gd" id="9"',
            self.escena,
        )
        self.assertIn('[node name="CinematicaSuenoController"', self.escena)
        self.assertIn('!= "casa"', self.controller)
        self.assertIn("_preparar_transicion_sueno(dia, mundo)", self.controller)
        self.assertIn(
            'String(hijo.get_meta("destino", "")) == "sueño"', self.controller
        )
        self.assertIn("callback.get_object() == dia", self.controller)

    def test_sueno_reactivo_conserva_su_contrato_dream_only(self) -> None:
        self.assertIn('!= "sueño"', self.reactivo)
        self.assertRegex(self.reactivo, r"SuenoUtileria\s*\.\s*montar\(")
        self.assertNotIn('== "archivo"', self.reactivo)
        self.assertNotIn('== "casa"', self.reactivo)
        self.assertNotIn('== "trayecto"', self.reactivo)
        self.assertNotIn("_preparar_transicion_sueno", self.reactivo)

    def test_el_evento_vuelve_al_flujo_oficial_sin_duplicar_reglas(self) -> None:
        self.assertNotIn("Jornada.", self.controller)
        self.assertNotIn("_aplicar_politica_sueno", self.controller)
        self.assertNotIn("guardar(", self.controller)
        fin = self.controller.split("func _terminar_transicion_sueno() -> void:", 1)[1]
        self.assertEqual(fin.count("dia._al_pisar_salida(dia._caminante, salida)"), 1)
        self.assertIn("dia.set_process(true)", fin)
        # Se restaura antes de reenviar: la entrada al sueño vuelve a bloquear.
        reenvio = fin.index("dia._al_pisar_salida(dia._caminante, salida)")
        self.assertLess(fin.index("dia._caminante.set_physics_process(true)"), reenvio)
        self.assertLess(fin.index("dia._hud.visible = true"), reenvio)

    def test_la_entrada_al_sueno_rueda_en_la_sala_real(self) -> None:
        entrada = (ROOT / "godot" / "guion" / "entrada_sueno_cinematica.gd").read_text(encoding="utf-8")
        sueno = (ROOT / "godot" / "guion" / "dia_sueno_app.gd").read_text(encoding="utf-8")
        self.assertNotIn('"tipo": "2d"', entrada)
        self.assertNotIn('"figura"', entrada)
        self.assertEqual(entrada.count('"tipo": "3d"'), 3)
        for dato in ('"entrada"', '"figuras"', '"carteles"', '"salidas"'):
            self.assertIn(dato, entrada)
        self.assertIn("_espacio_actual", sueno)

    def test_skip_y_fin_normal_comparten_el_mismo_callback(self) -> None:
        self.assertIn(
            "_cinematica_sueno.terminada.connect(_terminar_transicion_sueno)",
            self.controller,
        )
        salto = self.reproductor.split("func saltar() -> void:", 1)[1].split(
            "func _process", 1
        )[0]
        self.assertIn("_terminar()", salto)
        self.assertIn("terminada.emit()", self.reproductor)
        self.assertIn("Cinematica.anotar_vista(_estado, _id)", self.reproductor)

    def test_la_casa_queda_congelada_mientras_rueda(self) -> None:
        self.assertIn("dia.set_process(false)", self.controller)
        self.assertIn("dia._caminante.set_physics_process(false)", self.controller)
        self.assertIn("dia._caminante.set_physics_process(true)", self.controller)
        self.assertIn("dia._hud.visible = false", self.controller)
        self.assertIn("dia._hud.visible = true", self.controller)
        self.assertIn('!= "casa"', self.controller)


if __name__ == "__main__":
    unittest.main()
