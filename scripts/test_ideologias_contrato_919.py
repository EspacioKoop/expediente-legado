from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot/guion/dia_app.gd"
DIA_GATO = ROOT / "godot/guion/dia_gato_app.gd"
PROMETEO = ROOT / "godot/guion/prometeo.gd"


class IdeologiasContrato919Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.dia_gato = DIA_GATO.read_text(encoding="utf-8")
        cls.prometeo = PROMETEO.read_text(encoding="utf-8")

    def test_el_despertar_normal_y_forzado_limpian_solo_exposicion_diaria(self):
        llamada = "Prometeo.reiniciar_exposicion_ideologica_diaria(partida.estado)"
        self.assertEqual(self.dia.count(llamada), 2)
        self.assertIn("var dia := Jornada.despertar(jornada)\n\t\t\t\t" + llamada, self.dia)
        self.assertIn("var dia := Jornada.despertar_de_golpe(jornada)\n\t\t" + llamada, self.dia)

    def test_la_ruta_de_objetivos_oniricos_aplica_el_mismo_reset(self):
        llamada = "Prometeo.reiniciar_exposicion_ideologica_diaria(partida.estado)"
        self.assertEqual(self.dia_gato.count(llamada), 1)
        self.assertIn("dia_nuevo = Jornada.despertar(jornada)\n\t\t" + llamada, self.dia_gato)

    def test_fallo_de_guardado_restaura_exposicion_en_la_ruta_con_rollback(self):
        self.assertIn("var exposicion_antes: Array", self.dia_gato)
        self.assertIn(
            "partida.estado[Prometeo.CLAVE_EXPOSICION_IDEOLOGICA] = exposicion_antes",
            self.dia_gato,
        )

    def test_el_reset_diario_no_toca_elecciones_ni_lecturas_sociales(self):
        inicio = self.prometeo.index(
            "static func reiniciar_exposicion_ideologica_diaria(estado: Dictionary) -> void:"
        )
        fin = self.prometeo.index("\n\n", inicio)
        cuerpo = self.prometeo[inicio:fin]
        self.assertIn("estado[CLAVE_EXPOSICION_IDEOLOGICA] = []", cuerpo)
        self.assertNotIn("CLAVE_ELECCIONES_IDEOLOGICAS", cuerpo)
        self.assertNotIn("CLAVE_LECTURAS_SOCIALES", cuerpo)


if __name__ == "__main__":
    unittest.main()
