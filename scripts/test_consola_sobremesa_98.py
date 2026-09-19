from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONSOLA = ROOT / "godot" / "guion" / "consola_sobremesa_98.gd"
UTILERIA = ROOT / "godot" / "guion" / "casa_utileria.gd"
PORTATIL = ROOT / "godot" / "guion" / "consola_portatil_98.gd"


class ConsolaSobremesa98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.portatil = PORTATIL.read_text(encoding="utf-8")

    def test_reutiliza_backend_del_emulador_sin_duplicarlo(self):
        self.assertIn("extends ConsolaPortatil98", self.consola)
        self.assertNotIn("EmuladorPortatilAudioApp.new()", self.consola)
        self.assertIn("EmuladorPortatilAudioApp.new()", self.portatil)
        self.assertIn("activado.connect(_alternar)", self.consola)

    def test_es_un_objeto_de_sobremesa_reconocible_e_interactivo(self):
        self.assertIn('nombre_objeto = "consola de sobremesa"', self.consola)
        self.assertIn("verbo = Verbo.USAR", self.consola)
        self.assertIn("CollisionShape3D.new()", self.consola)
        self.assertIn("BoxShape3D.new()", self.consola)
        self.assertIn("_agregar_boton", self.consola)
        self.assertIn("emission_enabled = true", self.consola)

    def test_la_casa_la_monta_en_el_rincon_del_televisor(self):
        self.assertIn("_montar_consola_sobremesa(raiz", self.utileria)
        self.assertIn("ConsolaSobremesa98.new()", self.utileria)
        self.assertIn('consola.name = "ConsolaSobremesa98"', self.utileria)
        self.assertIn("Vector3(-3.58, 0.54, 2.10)", self.utileria)

    def test_ocio_sigue_sin_tocar_estado_de_campana(self):
        combinado = self.consola + self.portatil
        for termino in (
            "Partida.",
            "Jornada.",
            "pistas_descubiertas",
            "inventario",
            "dinero",
            "guardar(",
        ):
            self.assertNotIn(termino, combinado)

    def test_monta_tres_cartuchos_de_expositor(self):
        self.assertIn("_montar_cartuchos_expositor()", self.consola)
        self.assertEqual(self.consola.count("_agregar_cartucho("), 4)
        for nombre in (
            "caza_pixeles_98.jpg",
            "paper_planes_98.jpg",
            "croc_riders_98.jpg",
        ):
            self.assertIn(nombre, self.consola)

    def test_el_arte_es_local_y_no_convierte_props_en_roms(self):
        self.assertIn("res://arte/consola98/cartuchos/", self.consola)
        self.assertIn("Texture2D", self.consola)
        for termino in (
            "http://",
            "https://",
            ".gbc",
            ".gb",
            "EmuladorPortatilApp.new()",
        ):
            self.assertNotIn(termino, self.consola)


if __name__ == "__main__":
    unittest.main()
