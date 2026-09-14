import copy
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTENIDO = ROOT / "godot" / "guion" / "contenido.gd"
CASOS_ES = ROOT / "godot" / "datos" / "casos.json"
CASOS_EN = ROOT / "godot" / "datos" / "casos.en.json"

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
        cls.es = json.loads(CASOS_ES.read_text(encoding="utf-8"))
        cls.en = json.loads(CASOS_EN.read_text(encoding="utf-8"))

    def test_el_cargador_resuelve_locale_y_conserva_fallback_espanol(self):
        self.assertIn("TranslationServer.get_locale()", self.codigo)
        self.assertIn('"res://datos/%s.%s.json"', self.codigo)
        self.assertIn("_misma_estructura(base, localizada)", self.codigo)
        self.assertIn("return canonica", self.codigo)

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

    def test_ingles_actual_cae_en_fallback_hasta_recuperar_paridad(self):
        ids_es = {caso["id"] for caso in self.es["casos"]}
        ids_en = {caso["id"] for caso in self.en["casos"]}
        self.assertIn("caso9@9", ids_es - ids_en)
        self.assertFalse(misma_estructura(self.es, self.en))


if __name__ == "__main__":
    unittest.main()
