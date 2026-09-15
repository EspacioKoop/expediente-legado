from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CASTILLO = RAIZ / "godot" / "guion" / "sueno_castillo.gd"
FORMAS = RAIZ / "godot" / "guion" / "sueno_formas.gd"
SUENO = RAIZ / "godot" / "guion" / "sueno.gd"


class SuenoCastilloRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = CASTILLO.read_text(encoding="utf-8")
        cls.formas = FORMAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")

    def test_expone_adaptador_sin_duplicar_seleccion_nocturna(self):
        self.assertIn("static func adaptar_espacio(", self.texto)
        self.assertIn('resultado["identidad_onirica"] = ID', self.texto)
        self.assertIn('resultado["contorno"] = configurada["contorno"]', self.texto)
        self.assertIn('resultado["altura_contorno"]', self.texto)
        self.assertNotIn("Sueno.noche(", self.texto)
        self.assertNotIn("SuenoFormas", self.texto)

    def test_retorno_usa_solo_anclas_de_la_familia(self):
        self.assertIn('"retorno_patio"', self.texto)
        self.assertIn("anclas[posmod(vuelta, anclas.size())]", self.texto)
        self.assertIn('resultado["entrada"] = retorno.get(', self.texto)
        for aleatorio in ["randf(", "randi(", "randomize("]:
            self.assertNotIn(aleatorio, self.texto)

    def test_codice_reutiliza_contenido_conocido_y_no_inventa_texto(self):
        self.assertIn('contenido_conocido.get("frases", [])', self.texto)
        self.assertIn('"frase": frases[0]', self.texto)
        self.assertIn('"destino": ""', self.texto)
        self.assertIn('"visible": false', self.texto)
        self.assertIn('"carcasa": false', self.texto)

    def test_no_introduce_greybox_ni_estado_de_juego(self):
        for termino in ["Rect2i", "BoxMesh", "Jornada.", "Partida", "dinero", "veredicto"]:
            self.assertNotIn(termino, self.texto)

    def test_mantiene_fuentes_y_seleccion_cc0_del_vertical_base(self):
        self.assertIn("valsekamerplant.itch.io/psx-style-going-medieval", self.texto)
        self.assertIn("quaternius.com/packs/fantasypropsmegakit.html", self.texto)
        self.assertIn('LICENCIA := "CC0-1.0"', self.texto)
        self.assertEqual(self.texto.count('"grupo": "arquitectura"'), 3)
        self.assertEqual(self.texto.count('"grupo": "prop"'), 3)

    def test_patio_declara_castillo_sobre_familia_anular(self):
        self.assertIn('"familia_poligonal": SuenoFamilias.ANULAR', self.formas)
        self.assertIn('"identidad_onirica": SuenoCastillo.ID', self.formas)
        self.assertIn('"vuelta_castillo": 1', self.formas)
        self.assertIn('"semilla_castillo": 0', self.formas)

    def test_sueno_delega_presentacion_sin_hardcodear_patio(self):
        self.assertIn(
            'var identidad_onirica := String(forma.get("identidad_onirica", ""))',
            self.sueno,
        )
        self.assertIn('if identidad_onirica == SuenoCastillo.ID:', self.sueno)
        self.assertIn(
            'estado_presentacion.merge(contenido.get("estado_presentacion", {}), true)',
            self.sueno,
        )
        self.assertIn(
            "resultado = SuenoCastillo.adaptar_espacio(resultado, estado_presentacion, contenido)",
            self.sueno,
        )
        self.assertNotIn('id == "patio"', self.sueno)

    def test_adaptacion_ocurre_despues_del_contorno_poligonal(self):
        contorno = self.sueno.index('resultado["contorno"] = familia["contorno"]')
        adaptador = self.sueno.index("resultado = SuenoCastillo.adaptar_espacio(")
        self.assertLess(contorno, adaptador)


if __name__ == "__main__":
    unittest.main()
