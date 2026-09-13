import json
from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CATALOGO = RAIZ / "godot" / "datos" / "sellos.json"
SELL0S = RAIZ / "godot" / "guion" / "sellos.gd"


class SellosInternosTest(unittest.TestCase):
    def setUp(self):
        self.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        self.codigo = SELL0S.read_text(encoding="utf-8")

    def test_catalogo_tiene_ids_estables_y_claves_traducibles(self):
        ids = [entrada["id"] for entrada in self.catalogo]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertIn("planta-en-orden", ids)
        self.assertIn("noche-improductiva", ids)
        for entrada in self.catalogo:
            self.assertTrue(entrada["titulo"].startswith("SELLO_"))
            self.assertTrue(entrada["descripcion"].startswith("SELLO_"))
            self.assertIn("origen", entrada)

    def test_api_es_idempotente_y_explicita_claves_invalidas(self):
        self.assertIn("static func registrar_sello(estado: Dictionary, sello_id: String)", self.codigo)
        self.assertIn('"ya-obtenido"', self.codigo)
        self.assertIn('"desconocido"', self.codigo)
        self.assertIn("obtenidos.has(sello_id)", self.codigo)
        self.assertIn("estado[CLAVE_ESTADO] = obtenidos", self.codigo)

    def test_no_hay_dependencia_de_steam_ni_reglas_de_juego(self):
        for prohibido in ("GodotSteam", "Steam", "Jornada.", "Acusacion.", "Economia."):
            self.assertNotIn(prohibido, self.codigo)

    def test_consulta_publica_existe(self):
        self.assertIn("static func tiene_sello(estado: Dictionary, sello_id: String) -> bool", self.codigo)


if __name__ == "__main__":
    unittest.main()
