from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
RUTA = ROOT / "godot" / "guion" / "remate_vida.gd"


class RemateVidaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = RUTA.read_text(encoding="utf-8")

    def test_resume_solo_estado_existente(self):
        for campo in (
            'jornada.get("alquiler", {})',
            'jornada.get("gato", {})',
            'jornada.get("trabajillos", {})',
            'jornada.get("dinero", 0)',
            'jornada.get("vuelta", 1)',
        ):
            self.assertIn(campo, self.codigo)

    def test_no_hay_puntuacion_moral_ni_recompensa(self):
        for prohibido in (
            "puntuacion",
            "score",
            "acciones +=",
            "dinero +=",
            "pistas_descubiertas",
            "Partida.guardar",
        ):
            self.assertNotIn(prohibido, self.codigo)

    def test_conserva_el_final_de_investigacion(self):
        self.assertIn('"final_investigacion": final_investigacion', self.codigo)
        self.assertIn('"remate_vida": variante(estado)', self.codigo)
        self.assertIn('"resumen_vida": resumir(estado)', self.codigo)

    def test_hay_estados_contrastados(self):
        self.assertIn('const ESTABLE := "estable"', self.codigo)
        self.assertIn('const PRECARIA := "precaria"', self.codigo)
        self.assertIn('const SIN_HOGAR := "sin_hogar"', self.codigo)
        self.assertIn('impagos == 0', self.codigo)
        self.assertIn('not resumen["gato_presente"]', self.codigo)

    def test_recuerda_los_trabajillos_sin_puntuarlos(self):
        self.assertIn('trabajillos.get("hechos", 0)', self.codigo)
        self.assertIn('"trabajillos_hechos": trabajillos_hechos', self.codigo)
        self.assertIn('"trabajo_nocturno": trabajillos_hechos > 0', self.codigo)

        variante = self.codigo.split("static func variante", 1)[1].split(
            "static func resolver", 1
        )[0]
        self.assertNotIn("trabajillos_hechos", variante)
        self.assertNotIn("trabajo_nocturno", variante)


if __name__ == "__main__":
    unittest.main()
