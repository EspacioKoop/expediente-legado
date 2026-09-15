from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PRESENTACION = ROOT / "godot" / "guion" / "remate_vida_cinematica.gd"
DESPIDO = ROOT / "godot" / "guion" / "despido_cinematica.gd"


class RemateVidaCinematicaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.despido = DESPIDO.read_text(encoding="utf-8")

    def test_la_presentacion_consume_el_contrato_comun(self):
        self.assertIn("RemateVida.resumir(estado)", self.presentacion)
        self.assertIn("RemateVida.variante(estado)", self.presentacion)
        self.assertIn("Cinematica", self.presentacion)
        self.assertIn('const ID := "remate-vida"', self.presentacion)

    def test_hay_imagenes_para_los_tres_remates(self):
        self.assertIn("RemateVida.SIN_HOGAR", self.presentacion)
        self.assertIn("RemateVida.PRECARIA", self.presentacion)
        self.assertIn("_sin_hogar", self.presentacion)
        self.assertIn("_casa(bool(resumen.get(\"gato_presente\", true)), true)", self.presentacion)
        self.assertIn("_casa(bool(resumen.get(\"gato_presente\", true)), false)", self.presentacion)

    def test_el_gato_solo_aparece_si_seguia_presente(self):
        self.assertGreaterEqual(self.presentacion.count("if gato_presente:"), 2)
        self.assertIn('resumen.get("gato_presente", true)', self.presentacion)

    def test_no_hay_texto_moral_ni_mutacion_del_estado(self):
        self.assertNotIn('"rotulo":', self.presentacion)
        self.assertNotIn('"voz":', self.presentacion)
        self.assertNotIn('estado[', self.presentacion)
        self.assertNotIn("Partida.guardar", self.presentacion)

    def test_despido_conserva_api_y_puede_anexar_el_remate(self):
        self.assertIn(
            "static func planos_de(gato_presente: bool, vistas: int = 0, voz_cunado: String = \"\")",
            self.despido,
        )
        self.assertIn("static func planos_con_remate(", self.despido)
        self.assertIn("RemateVida.resumir(estado)", self.despido)
        self.assertIn("RemateVidaCinematica.planos_de(estado, vistas)", self.despido)
        self.assertIn("planos.append_array", self.despido)


if __name__ == "__main__":
    unittest.main()
