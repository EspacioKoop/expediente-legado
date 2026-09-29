from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
REFUGIO = ROOT / "godot" / "guion" / "desvio_refugio_3d.gd"
CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"


class DesvioRefugio1774Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.refugio = REFUGIO.read_text(encoding="utf-8")
        cls.calle = CALLE.read_text(encoding="utf-8")

    def test_el_trayecto_monta_el_desvio_sin_nueva_fase(self):
        self.assertIn("DesvioRefugio3D.montar(calle, jornada)", self.calle)
        self.assertNotIn('"refugio"', self.calle)

    def test_el_refugio_solo_lee_clima_y_no_toca_progreso(self):
        self.assertIn("Clima.precipitacion(clima)", self.refugio)
        self.assertIn('jornada.get("clima_forzado", "")', self.refugio)
        for forbidden in (
            "Jornada.gastar",
            "SemillasOniricas",
            "Inventario",
            "TiendaVideojuegos",
            "partida.estado",
        ):
            self.assertNotIn(forbidden, self.refugio)

    def test_el_bucle_lateral_declara_retorno_y_no_colision(self):
        self.assertIn('"EntradaDesvio"', self.refugio)
        self.assertIn('"SalidaDesvio"', self.refugio)
        self.assertIn('"retorno_principal"', self.refugio)
        self.assertNotIn("StaticBody3D.new()", self.refugio)
        self.assertNotIn("CollisionShape3D.new()", self.refugio)

    def test_lluvia_y_nieve_tienen_presentacion_distinta(self):
        self.assertIn("Clima.LLUVIA", self.refugio)
        self.assertIn('"CharcoExterior"', self.refugio)
        self.assertIn('"GoteoBorde_%s"', self.refugio)
        self.assertIn("Clima.NIEVE", self.refugio)
        self.assertIn('"NieveBordeTecho"', self.refugio)


if __name__ == "__main__":
    unittest.main()
