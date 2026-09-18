from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CASTILLO = RAIZ / "godot" / "guion" / "sueno_castillo.gd"
FORMAS = RAIZ / "godot" / "guion" / "sueno_formas.gd"
SUENO = RAIZ / "godot" / "guion" / "sueno.gd"
DIA = RAIZ / "godot" / "guion" / "dia_app.gd"
DIA_SUENO = RAIZ / "godot" / "guion" / "dia_sueno_app.gd"
ESPACIO_3D = RAIZ / "godot" / "guion" / "espacio_3d.gd"


class SuenoCastilloRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = CASTILLO.read_text(encoding="utf-8")
        cls.formas = FORMAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.dia_sueno = DIA_SUENO.read_text(encoding="utf-8")
        cls.espacio_3d = ESPACIO_3D.read_text(encoding="utf-8")

    def test_expone_adaptador_sin_duplicar_seleccion_nocturna(self):
        self.assertIn("static func adaptar_espacio(", self.texto)
        self.assertIn('resultado["identidad_onirica"] = ID', self.texto)
        self.assertIn('resultado["contorno"] = configurada["contorno"]', self.texto)
        self.assertIn('resultado["altura_contorno"]', self.texto)
        self.assertNotIn("Sueno.noche(", self.texto)
        self.assertNotIn("SuenoFormas", self.texto)

    def test_variante_castillo_es_determinista_y_no_cambia_la_fisica(self):
        self.assertIn(
            'const VARIANTES := ["patio", "scriptorium", "torre_capilla", "claustro_reflejado"]',
            self.texto,
        )
        self.assertIn('const MUTACIONES := ["estable", "desfase", "contraccion", "giro"]', self.texto)
        self.assertIn("posmod(semilla + maxi(0, vuelta - 1), VARIANTES.size())", self.texto)
        self.assertIn('resultado["variante_castillo"]', self.texto)
        self.assertIn("posmod(semilla + vuelta * 3, MUTACIONES.size())", self.texto)
        self.assertIn('resultado["mutacion_castillo"]', self.texto)
        self.assertNotIn('resultado["familia_poligonal"] =', self.texto)

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
        self.assertIn('"evento": "codice_castillo"', self.texto)

    def test_evento_del_codice_viaja_por_la_interaccion_comun(self):
        self.assertIn('zona.set_meta("evento", salida.get("evento", ""))', self.espacio_3d)
        self.assertNotIn("codice_castillo", self.espacio_3d)
        self.assertIn('salida.get_meta("evento", "")', self.dia_sueno)
        self.assertIn('evento == "codice_castillo"', self.dia_sueno)
        self.assertIn("SuenoCastillo3D.reaccionar_a_lectura(_mundo)", self.dia_sueno)
        self.assertIn('salida.set_meta("reaccion_castillo", true)', self.dia_sueno)

    def test_no_introduce_greybox_ni_estado_de_juego(self):
        for termino in ["Rect2i", "BoxMesh", "Jornada.", "Partida", "dinero", "veredicto"]:
            self.assertNotIn(termino, self.texto)

    def test_runtime_no_publica_deuda_de_assets_cc0(self):
        self.assertNotIn("SELECCION_MINIMA", self.texto)
        self.assertNotIn('"seleccion_onirica"', self.texto)
        self.assertNotIn("valsekamerplant.itch.io", self.texto)
        self.assertNotIn("quaternius.com/packs/fantasypropsmegakit.html", self.texto)

    def test_runtime_deriva_variante_de_la_noche_sin_estado_persistente_extra(self):
        self.assertIn("var semilla_noche := Sueno.semilla(", self.dia)
        self.assertIn('forma_actual.get("identidad_onirica", "")', self.dia)
        self.assertIn("== SuenoCastillo.ID", self.dia)
        self.assertIn('estado_castillo["vuelta_castillo"] = cual + 1', self.dia)
        self.assertIn('estado_castillo["semilla_castillo"] = semilla_noche', self.dia)
        self.assertNotIn('if id == "patio"', self.dia)

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
