import copy
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTENIDO = ROOT / "godot" / "guion" / "contenido.gd"
HISTORIAS = ROOT / "godot" / "guion" / "historias.gd"
CASOS_ES = ROOT / "godot" / "datos" / "casos.json"
CASOS_EN = ROOT / "godot" / "datos" / "casos.en.json"
PROMETEO_ES = ROOT / "godot" / "datos" / "prometeo.json"
PROMETEO_EN = ROOT / "godot" / "datos" / "prometeo.en.json"
ESTADO_LOCALES = ROOT / "godot" / "datos" / "catalogos.locales.json"

CAMPOS_TRADUCIBLES = {
    "titulo",
    "descripcion",
    "contenido",
    "fraseGatillo",
    "nombre",
    "desenlace",
    "resumen",
    "requisito",
    "texto",
    "etiqueta",
    "secuelaUtil",
    "secuelaConfusion",
}


def misma_estructura(base, localizada, campo=""):
    """Espejo del contrato de Contenido: texto puede variar; reglas no."""
    if type(base) is not type(localizada):
        return False
    if isinstance(base, dict):
        if base.keys() != localizada.keys():
            return False
        return all(
            misma_estructura(base[clave], localizada[clave], clave) for clave in base
        )
    if isinstance(base, list):
        if len(base) != len(localizada):
            return False
        return all(
            misma_estructura(valor, localizada[indice], campo)
            for indice, valor in enumerate(base)
        )
    if campo in CAMPOS_TRADUCIBLES:
        return True
    return base == localizada


class CatalogoLocaleTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = CONTENIDO.read_text(encoding="utf-8")
        cls.historias = HISTORIAS.read_text(encoding="utf-8")
        cls.es = json.loads(CASOS_ES.read_text(encoding="utf-8"))
        cls.en = json.loads(CASOS_EN.read_text(encoding="utf-8"))
        cls.prometeo_es = json.loads(PROMETEO_ES.read_text(encoding="utf-8"))
        cls.prometeo_en = json.loads(PROMETEO_EN.read_text(encoding="utf-8"))
        cls.estado_locales = json.loads(ESTADO_LOCALES.read_text(encoding="utf-8"))

    def test_el_cargador_resuelve_locale_y_conserva_fallback_espanol(self):
        self.assertIn("TranslationServer.get_locale()", self.codigo)
        self.assertIn('"res://datos/%s.%s.json"', self.codigo)
        self.assertIn("_misma_estructura(base, localizada)", self.codigo)
        self.assertIn("return canonica", self.codigo)

    def test_historias_resuelve_prometeo_con_el_mismo_contrato(self):
        self.assertIn('Contenido.ruta_catalogo("prometeo")', self.historias)
        self.assertIn('func cargar(ruta: String = "")', self.historias)

    def test_catalogos_ingleses_recuperan_paridad_sin_activar_traduccion_incompleta(self):
        self.assertTrue(misma_estructura(self.es, self.en))
        self.assertTrue(misma_estructura(self.prometeo_es, self.prometeo_en))
        self.assertFalse(self.estado_locales["casos"]["en"])
        self.assertTrue(self.estado_locales["prometeo"]["en"])
        self.assertNotIn("QUERY LENGTH LIMIT EXCEEDED", CASOS_EN.read_text(encoding="utf-8"))
        self.assertNotIn("QUERY LENGTH LIMIT EXCEEDED", PROMETEO_EN.read_text(encoding="utf-8"))
        self.assertIn("_catalogo_localizado_completo(nombre, idioma)", self.codigo)

    def test_prometeo_ingles_traduce_todos_los_logros(self):
        for logro_es, logro_en in zip(
            self.prometeo_es["logros"], self.prometeo_en["logros"], strict=True
        ):
            self.assertEqual(logro_es["id"], logro_en["id"])
            self.assertNotEqual(logro_es["titulo"], logro_en["titulo"])
            self.assertNotEqual(logro_es["descripcion"], logro_en["descripcion"])

    def test_prometeo_ingles_traduce_todo_el_tarot(self):
        for carta_es, carta_en in zip(
            self.prometeo_es["tarot"], self.prometeo_en["tarot"], strict=True
        ):
            self.assertEqual(carta_es["id"], carta_en["id"])
            self.assertNotEqual(carta_es["nombre"], carta_en["nombre"])
            self.assertNotEqual(carta_es["descripcion"], carta_en["descripcion"])
            if carta_es["requisito"]:
                self.assertNotEqual(carta_es["requisito"], carta_en["requisito"])

    def test_prometeo_ingles_traduce_todas_las_historias(self):
        for historia_id, historia_es in self.prometeo_es["historias"].items():
            historia_en = self.prometeo_en["historias"][historia_id]
            self.assertNotEqual(historia_es["texto"], historia_en["texto"])
            self.assertNotEqual(historia_es["secuelaUtil"], historia_en["secuelaUtil"])
            self.assertNotEqual(
                historia_es["secuelaConfusion"], historia_en["secuelaConfusion"]
            )
            for opcion_es, opcion_en in zip(
                historia_es["opciones"], historia_en["opciones"], strict=True
            ):
                self.assertEqual(opcion_es["eje"], opcion_en["eje"])
                self.assertNotEqual(opcion_es["etiqueta"], opcion_en["etiqueta"])
                self.assertNotEqual(opcion_es["texto"], opcion_en["texto"])

    def test_casos_1_a_4_estan_traducidos_al_ingles(self):
        for indice in (0, 1, 2, 3):
            caso_es = self.es["casos"][indice]
            caso_en = self.en["casos"][indice]
            self.assertEqual(caso_es["id"], caso_en["id"])
            self.assertNotEqual(caso_es["descripcion"], caso_en["descripcion"])
            for registro_es, registro_en in zip(
                caso_es["registros"], caso_en["registros"], strict=True
            ):
                self.assertNotEqual(registro_es["contenido"], registro_en["contenido"])
            for pista_es, pista_en in zip(
                caso_es["pistas"], caso_en["pistas"], strict=True
            ):
                self.assertNotEqual(pista_es["descripcion"], pista_en["descripcion"])
                if "fraseGatillo" in pista_es:
                    self.assertNotEqual(
                        pista_es["fraseGatillo"], pista_en["fraseGatillo"]
                    )
            for sospechoso_es, sospechoso_en in zip(
                caso_es["sospechosos"], caso_en["sospechosos"], strict=True
            ):
                self.assertNotEqual(
                    sospechoso_es["descripcion"], sospechoso_en["descripcion"]
                )
                self.assertNotEqual(
                    sospechoso_es["desenlace"], sospechoso_en["desenlace"]
                )

    def test_el_contrato_permite_traducir_texto_pero_no_quitar_fichas(self):
        traducida = copy.deepcopy(self.es)
        traducida["casos"][0]["descripcion"] = "Translated text"
        self.assertTrue(misma_estructura(self.es, traducida))

        incompleta = copy.deepcopy(traducida)
        incompleta["casos"].pop()
        self.assertFalse(misma_estructura(self.es, incompleta))

    def test_el_contrato_no_permite_cambiar_identidad_o_reglas(self):
        alterada = copy.deepcopy(self.es)
        alterada["casos"][0]["id"] = "otro-id"
        self.assertFalse(misma_estructura(self.es, alterada))

        alterada = copy.deepcopy(self.es)
        alterada["casos"][0]["principal"] = not alterada["casos"][0]["principal"]
        self.assertFalse(misma_estructura(self.es, alterada))

    def test_ingles_tiene_las_mismas_fichas_pero_sigue_marcado_incompleto(self):
        ids_es = {caso["id"] for caso in self.es["casos"]}
        ids_en = {caso["id"] for caso in self.en["casos"]}
        self.assertEqual(ids_es, ids_en)
        self.assertTrue(misma_estructura(self.es, self.en))
        self.assertFalse(self.estado_locales["casos"]["en"])


if __name__ == "__main__":
    unittest.main()
