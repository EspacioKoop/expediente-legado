from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CINEMATICA = ROOT / "godot" / "guion" / "sueno_cinematica.gd"
CAPA = ROOT / "godot" / "guion" / "dia_cinematica_sueno_app.gd"
CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"


class SuenoCinematica3DTest(unittest.TestCase):
    def setUp(self) -> None:
        self.cinematica = CINEMATICA.read_text(encoding="utf-8")
        self.capa = CAPA.read_text(encoding="utf-8")
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

    def test_capa_se_inserta_sin_tocar_la_raiz_del_dia(self) -> None:
        self.assertIn(
            'extends "res://guion/dia_cinematica_sueno_app.gd"', self.calle
        )
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', self.capa)
        self.assertIn('String(jornada.get("fase", "")) != "casa"', self.capa)
        self.assertIn('String(salida.get_meta("destino", "")) != "sueño"', self.capa)
        self.assertIn("super._al_pisar_salida(cuerpo, salida)", self.capa)

    def test_economia_y_fase_se_aplican_despues_de_la_cinematica(self) -> None:
        inicio = self.capa.split("func _iniciar_cinematica_sueno() -> void:", 1)[1].split(
            "func _terminar_cinematica_sueno", 1
        )[0]
        fin = self.capa.split("func _terminar_cinematica_sueno() -> void:", 1)[1]
        self.assertNotIn("Jornada.dormir(jornada)", inicio)
        self.assertEqual(fin.count("Jornada.dormir(jornada)"), 1)
        self.assertIn("_aplicar_politica_sueno()", fin)
        self.assertIn('_entrar_en("sueño")', fin)
        self.assertIn('_guardar_o_avisar("")', fin)

    def test_skip_y_fin_normal_comparten_el_mismo_callback(self) -> None:
        self.assertIn(
            "_cinematica_sueno.terminada.connect(_terminar_cinematica_sueno)",
            self.capa,
        )
        salto = self.reproductor.split("func saltar() -> void:", 1)[1].split(
            "func _process", 1
        )[0]
        self.assertIn("_terminar()", salto)
        self.assertIn("terminada.emit()", self.reproductor)
        self.assertIn("Cinematica.anotar_vista(_estado, _id)", self.reproductor)

    def test_mundo_domestico_queda_congelado_mientras_rueda(self) -> None:
        self.assertIn("if _cinematica_sueno != null:", self.capa)
        self.assertIn("_caminante.set_physics_process(false)", self.capa)
        self.assertIn("_caminante.set_physics_process(true)", self.capa)
        self.assertIn("_hud.visible = false", self.capa)
        self.assertIn("_hud.visible = true", self.capa)


if __name__ == "__main__":
    unittest.main()
