from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
DUAT = RAIZ / "godot" / "guion" / "sueno_duat.gd"


class SuenoDuatTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = DUAT.read_text(encoding="utf-8")

    def test_semilla_solo_se_activa_al_completar_fragmento(self):
        self.assertIn('const ID := "duat"', self.texto)
        self.assertIn('const FUENTE_TV := "tv:microdocumental_excavaciones_98"', self.texto)
        self.assertIn("if not fragmento_completado:", self.texto)
        self.assertIn(
            "SemillasOniricas.activar_semilla_onirica(jornada, ID, FUENTE_TV, 1)",
            self.texto,
        )
        self.assertIn("SemillasOniricas.familias_activas(jornada).has(ID)", self.texto)

    def test_pesaje_usa_solo_objetos_manipulados_y_peso_observable(self):
        self.assertIn('objeto.get("manipulado_hoy", false)', self.texto)
        self.assertIn('objeto.get("peso", 0.0)', self.texto)
        self.assertIn('objeto.get("peso_sellado", peso)', self.texto)
        self.assertIn('"regla": "peso_observable"', self.texto)
        for campo in ['"moral"', '"culpa"', '"bueno"', '"malo"', '"pecado"']:
            self.assertNotIn(campo, self.texto.lower())

    def test_reto_es_reproducible_sin_rng_implicito(self):
        self.assertIn("ids.sort()", self.texto)
        self.assertIn("posmod(semilla, validos.size())", self.texto)
        self.assertIn("posmod(semilla, 2)", self.texto)
        for aleatorio in ["randomize(", "randf(", "randi(", "RandomNumberGenerator"]:
            self.assertNotIn(aleatorio, self.texto)

    def test_el_objetivo_tiene_solucion_con_los_objetos_del_reto(self):
        preparar = self.texto.split("static func preparar_pesaje(", 1)[1].split(
            "static func evaluar_pesaje(", 1
        )[0]
        self.assertIn("if indice % 2 == paridad:", preparar)
        self.assertIn('objetos[indice].get("peso", 0.0)', preparar)
        self.assertIn('"peso_objetivo": peso_objetivo', preparar)

    def test_reduccion_movimiento_solo_cambia_presentacion(self):
        presentar = self.texto.split("static func presentacion(", 1)[1].split(
            "static func adaptar_espacio(", 1
        )[0]
        self.assertIn('"movimiento_arquitectura": "corte_fundido"', presentar)
        self.assertIn('"parpadeo_crt": 0.0', presentar)
        self.assertIn('"movimiento_arquitectura": "desplazamiento_continuo"', presentar)

        preparar = self.texto.split("static func preparar_pesaje(", 1)[1].split(
            "static func evaluar_pesaje(", 1
        )[0]
        self.assertNotIn("reduccion_movimiento", preparar)

    def test_adaptador_reutiliza_arquitectura_sin_tocar_wiring_central(self):
        self.assertIn("static func adaptar_espacio(", self.texto)
        self.assertIn("SuenoFamilias.de(SuenoFamilias.CONVERGENTE)", self.texto)
        self.assertIn('resultado["identidad_onirica"] = ID', self.texto)
        self.assertIn('resultado["duat_pesaje"] = preparar_pesaje(', self.texto)
        self.assertIn('"peso_arquitectura": true', self.texto)
        self.assertIn('"piramide_invertida": true', self.texto)
        for termino in ["Sueno.noche(", "SuenoFormas", "Partida", "veredicto", "dinero"]:
            self.assertNotIn(termino, self.texto)

    def test_prototipo_3d_materializa_balanza_y_pesos_interactivos(self):
        self.assertIn("static func crear_prototipo_3d(", self.texto)
        self.assertIn('balanza.name = "Balanza"', self.texto)
        self.assertIn('area.set_meta("duat_interaccion", "pesar")', self.texto)
        self.assertIn("Area3D.new()", self.texto)
        self.assertIn("SphereShape3D.new()", self.texto)
        self.assertNotIn("BoxMesh.new()", self.texto)

    def test_equilibrio_transforma_dos_piramides_y_accesibilidad_es_discreta(self):
        self.assertIn("static func aplicar_pesaje_3d(", self.texto)
        self.assertIn('"PiramideInferior"', self.texto)
        self.assertIn('"PiramideInvertida"', self.texto)
        transformar = self.texto.split("static func _transformar_arquitectura(", 1)[1].split(
            "static func _material(", 1
        )[0]
        self.assertIn("if reduccion_movimiento:", transformar)
        self.assertIn('tween.tween_property(inferior, "position"', transformar)
        self.assertIn('tween.tween_property(invertida, "position"', transformar)
        self.assertIn('tween.tween_property(arquitectura, "rotation_degrees"', transformar)

    def test_no_copia_franquicias_noventeras(self):
        texto = self.texto.lower()
        for franquicia in ["stargate", "tomb raider", "lara croft"]:
            self.assertNotIn(franquicia, texto)


if __name__ == "__main__":
    unittest.main()
