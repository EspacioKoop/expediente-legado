import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOGO_PATH = ROOT / "godot/datos/creditos.json"
LECTOR_PATH = ROOT / "godot/guion/creditos_inicio.gd"
PROCEDENCIA_PATH = ROOT / "godot/assets/procedencia.json"

ORDEN = ["open_source", "agradecimientos", "desarrollo", "direccion", "titulo"]


class CreditosInicioTest(unittest.TestCase):
    def setUp(self) -> None:
        self.catalogo = json.loads(CATALOGO_PATH.read_text(encoding="utf-8"))
        self.lector = LECTOR_PATH.read_text(encoding="utf-8")
        self.procedencia = json.loads(PROCEDENCIA_PATH.read_text(encoding="utf-8"))

    def test_orden_editorial_es_explicito_y_completo(self) -> None:
        self.assertEqual(self.catalogo["orden"], ORDEN)
        bloques = self.catalogo["bloques"]
        ids = [bloque["id"] for bloque in bloques]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(set(ids), set(ORDEN))

    def test_tecnologias_tienen_licencia_y_fuente_verificable(self) -> None:
        bloques = {bloque["id"]: bloque for bloque in self.catalogo["bloques"]}
        entradas = bloques["open_source"]["entradas"]
        self.assertGreaterEqual(len(entradas), 3)
        for entrada in entradas:
            self.assertTrue(entrada["nombre"])
            self.assertTrue(entrada["licencia"])
            fuente = ROOT / entrada["fuente"]
            self.assertTrue(fuente.is_file(), f"fuente de crédito ausente: {fuente}")

        catalogos = bloques["open_source"]["catalogos"]
        self.assertEqual(catalogos[0]["ruta"], "res://assets/procedencia.json")
        self.assertEqual(catalogos[0]["agrupar_por"], ["autor", "licencia", "fuente"])

    def test_agradecimientos_no_se_inventan(self) -> None:
        bloques = {bloque["id"]: bloque for bloque in self.catalogo["bloques"]}
        agradecimientos = bloques["agradecimientos"]
        self.assertTrue(agradecimientos["pendiente"])
        self.assertEqual(agradecimientos["entradas"], [])

    def test_desarrollo_direccion_y_titulo_reflejan_la_decision_del_issue(self) -> None:
        bloques = {bloque["id"]: bloque for bloque in self.catalogo["bloques"]}
        nombres = [entrada["nombre"] for entrada in bloques["desarrollo"]["entradas"]]
        self.assertEqual(
            nombres,
            [
                "eGurucharri",
                "VaroTv7",
                "Odiseo",
                "Codex",
                "Claude Opus 5",
                "Claude Sonnet 5",
            ],
        )
        self.assertEqual(
            bloques["direccion"]["entradas"],
            [{"nombre": "Dirigido por Eloy Gurucharri"}],
        )
        self.assertEqual(bloques["titulo"]["entradas"], [{"nombre": "SIGA 98"}])

    def test_assets_se_derivan_del_catalogo_de_procedencia_sin_duplicarlo(self) -> None:
        self.assertIn('const RUTA_PROCEDENCIA := "res://assets/procedencia.json"', self.lector)
        self.assertIn('datos.get("assets", [])', self.lector)
        for campo in ("autor", "licencia", "fuente"):
            self.assertIn(f'entrada.get("{campo}", "")', self.lector)
        self.assertIn("atribuciones_assets()", self.lector)
        self.assertGreater(len(self.procedencia.get("assets", [])), 0)

    def test_lector_es_puro_y_no_arranca_la_cinematica(self) -> None:
        self.assertIn('const RUTA_CATALOGO := "res://datos/creditos.json"', self.lector)
        self.assertIn("static func bloques()", self.lector)
        self.assertIn("static func bloques_completos()", self.lector)
        for prohibido in ("change_scene", "instantiate()", "reproducir(", "Partida", "Jornada"):
            self.assertNotIn(prohibido, self.lector)


if __name__ == "__main__":
    unittest.main()
