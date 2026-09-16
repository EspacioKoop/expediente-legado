from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CINEMATICA = ROOT / "godot" / "guion" / "cinematica.gd"
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"
MESA = ROOT / "godot" / "guion" / "mesa_cinematica.gd"
SELLO = ROOT / "godot" / "guion" / "sello_cinematica.gd"
TAROT = ROOT / "godot" / "guion" / "tarot_cinematica.gd"


class CinematicasSelloTarot3DTest(unittest.TestCase):
    def setUp(self) -> None:
        self.cinematica = CINEMATICA.read_text(encoding="utf-8")
        self.reproductor = REPRODUCTOR.read_text(encoding="utf-8")
        self.mesa = MESA.read_text(encoding="utf-8")
        self.sello = SELLO.read_text(encoding="utf-8")
        self.tarot = TAROT.read_text(encoding="utf-8")

    def test_sello_se_rueda_entero_en_3d(self) -> None:
        self.assertEqual(self.sello.count('"tipo": "3d"'), 3)
        self.assertNotIn('"tipo": "2d"', self.sello)
        self.assertNotIn('"figura":', self.sello)
        for nombre in ('"a7"', '"sello"', '"carpeta"'):
            self.assertIn(f'"nombre": {nombre}', self.sello)
        self.assertGreaterEqual(self.sello.count("MesaCinematica.con("), 3)
        self.assertIn("_marca(precipitada", self.sello)

    def test_tarot_se_rueda_entero_en_3d(self) -> None:
        self.assertEqual(self.tarot.count('"tipo": "3d"'), 4)
        self.assertNotIn('"tipo": "2d"', self.tarot)
        self.assertNotIn('"figura":', self.tarot)
        for nombre in ('"reverso"', '"canto"', '"frontal"', '"entrega"'):
            self.assertIn(f'"nombre": {nombre}', self.tarot)
        self.assertIn('plano["decorado"] = decorado', self.tarot)
        self.assertIn('"emisivo": emisivo', self.tarot)
        self.assertIn('"carcasa": false', self.tarot)

    def test_plato_3d_es_generico_y_no_conoce_sello_ni_tarot(self) -> None:
        for contrato in (
            "SubViewportContainer.new()",
            "_vista_plato.own_world_3d = true",
            "func _preparar_plato(decorado: Dictionary) -> void:",
            "Espacio3D.construir(_decorado, decorado)",
            'plano.get("decorado", {})',
        ):
            self.assertIn(contrato, self.reproductor)
        self.assertNotIn("SelloCinematica", self.reproductor)
        self.assertNotIn("TarotCinematica", self.reproductor)
        self.assertIn(
            'plano.has("decorado") and not (plano["decorado"] is Dictionary)',
            self.cinematica,
        )

    def test_mesa_reutiliza_identidad_visual_de_la_oficina(self) -> None:
        self.assertIn("EspaciosCatalogo.OFICINA", self.mesa)
        self.assertIn('"modelo": "desk"', self.mesa)
        self.assertIn('"modelo": "computerScreen"', self.mesa)
        for textura in ("textura_suelo", "textura_muro", "textura_techo"):
            self.assertIn(f'"{textura}": oficina["{textura}"]', self.mesa)

    def test_skip_y_reduccion_de_movimiento_siguen_en_el_reproductor_comun(self) -> None:
        salto = self.reproductor.split("func saltar() -> void:", 1)[1].split(
            "func _process", 1
        )[0]
        self.assertIn("_terminar()", salto)
        self.assertIn("reduccion_movimiento", self.reproductor)
        self.assertIn("0.0 if _reduccion_movimiento else avance", self.reproductor)
        self.assertIn("Cinematica.anotar_vista(_estado, _id)", self.reproductor)


if __name__ == "__main__":
    unittest.main()
