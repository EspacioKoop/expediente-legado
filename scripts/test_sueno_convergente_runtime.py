from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
FORMAS = RAIZ / "godot" / "guion" / "sueno_formas.gd"
SUENO = RAIZ / "godot" / "guion" / "sueno.gd"
ESPACIO = RAIZ / "godot" / "guion" / "espacio_3d.gd"


class SuenoConvergenteRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.formas = FORMAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.espacio = ESPACIO.read_text(encoding="utf-8")

    def test_embudo_declara_familia_sin_condicional_por_nombre(self):
        self.assertIn('"familia_poligonal": SuenoFamilias.CONVERGENTE', self.formas)
        self.assertNotIn('id == "embudo"', self.sueno)
        self.assertNotIn('"embudo"', self.espacio)

    def test_sueno_publica_contorno_y_altura_al_runtime(self):
        self.assertIn('resultado["contorno"] = familia["contorno"]', self.sueno)
        self.assertIn('resultado["altura_contorno"]', self.sueno)
        self.assertIn('_salida_poligonal(familia)', self.sueno)
        self.assertIn('_sitios_poligonales(familia, base_salida)', self.sueno)
        self.assertIn('_carteles_poligonales(familia, frases)', self.sueno)

    def test_conserva_planta_logica_pero_remapea_la_entrada_runtime(self):
        self.assertIn('"planta": bloques', self.sueno)
        self.assertIn('"entrada": posicion_entrada', self.sueno)
        self.assertIn('familia["entrada"]', self.sueno)

    def test_espacio_prioriza_poligono_sobre_planta(self):
        bloque_contorno = self.espacio.index('if espacio.has("contorno")')
        bloque_planta = self.espacio.index('elif espacio.has("planta")')
        self.assertLess(bloque_contorno, bloque_planta)
        self.assertIn(
            "SuenoGeometria.cuerpo_sala(contorno, altura, tabiques)", self.espacio
        )
        self.assertIn('espacio.get("tabiques_poligonales", [])', self.espacio)

    def test_no_superpone_colision_ortogonal_al_poligono(self):
        inicio = self.espacio.index('if espacio.has("contorno")')
        fin = self.espacio.index('for bulto in espacio.get("bultos", [])')
        seleccion = self.espacio[inicio:fin]
        self.assertIn('elif espacio.has("planta")', seleccion)
        self.assertNotIn(
            '_por_planta(\n\t\t\traiz,\n\t\t\tespacio["planta"]',
            seleccion.split('elif espacio.has("planta")')[0],
        )

    def test_corte_no_activa_semillas_mitologicas(self):
        combinado = self.formas + self.sueno + self.espacio
        self.assertNotIn("semilla_onirica_gilgamesh", combinado)
        self.assertNotIn("activar_semilla_onirica", combinado)


if __name__ == "__main__":
    unittest.main()
