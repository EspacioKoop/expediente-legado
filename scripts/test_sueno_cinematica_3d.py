from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CINEMATICA = ROOT / "godot" / "guion" / "sueno_cinematica.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"


class SuenoCinematica3DTest(unittest.TestCase):
    def setUp(self) -> None:
        self.cinematica = CINEMATICA.read_text(encoding="utf-8")
        self.controller = CONTROLLER.read_text(encoding="utf-8")
        self.calle = CALLE.read_text(encoding="utf-8")
        self.reproductor = REPRODUCTOR.read_text(encoding="utf-8")

    def test_transicion_es_3d_y_reutiliza_la_casa(self) -> None:
        self.assertEqual(self.cinematica.count('"tipo": "3d"'), 3)
        self.assertNotIn('"tipo": "2d"', self.cinematica)
        self.assertNotIn('"figura":', self.cinematica)
        self.assertEqual(self.cinematica.count('"camara": Vector3'), 3)
        self.assertEqual(self.cinematica.count('"mira": Vector3'), 3)
        self.assertIn("EspaciosCatalogo.CASA", self.cinematica)
        self.assertNotIn("MeshInstance3D", self.cinematica)
        self.assertNotIn("BoxMesh", self.cinematica)

    def test_no_cambia_la_cadena_historica_del_dia(self) -> None:
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', self.calle)
        self.assertIn('if fase == "casa":', self.controller)
        self.assertIn("_preparar_transicion_sueno(dia, mundo)", self.controller)
        self.assertIn('String(hijo.get_meta("destino", "")) == "sueño"', self.controller)
        self.assertIn("callback.get_object() == dia", self.controller)

    def test_el_evento_vuelve_al_flujo_oficial_sin_duplicar_jornada(self) -> None:
        self.assertNotIn("Jornada.dormir", self.controller)
        self.assertNotIn("_aplicar_politica_sueno", self.controller)
        fin = self.controller.split("func _terminar_transicion_sueno() -> void:", 1)[1]
        self.assertEqual(fin.count("dia._al_pisar_salida(dia._caminante, salida)"), 1)
        self.assertIn("dia.set_process(true)", fin)

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
        self.assertIn('if fase != "sueño":', self.controller)

    def test_conserva_el_dressing_reactivo_preexistente(self) -> None:
        self.assertIn("SuenoUtileria", self.controller)
        self.assertIn(". montar(", self.controller)
        self.assertIn('String(escenas[0])', self.controller)
        self.assertIn("dia._raiz()", self.controller)


if __name__ == "__main__":
    unittest.main()
