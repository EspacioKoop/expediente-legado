from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HISTORIAS = ROOT / "godot" / "guion" / "historias.gd"


class HistoriasPosponerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = HISTORIAS.read_text(encoding="utf-8")

    def test_posponer_no_resuelve_la_historia(self):
        bloque = self.codigo.split("func postergar", 1)[1].split("func esta_pospuesta", 1)[0]
        self.assertIn('estado.get("historias_cartas", {}).has(carta_id)', bloque)
        self.assertIn('estado["historias_pospuestas"]', bloque)
        self.assertNotIn('historias[carta_id] =', bloque)
        self.assertNotIn("Prometeo.", bloque)

    def test_reabrir_conserva_el_catalogo_y_marca_estado(self):
        bloque = self.codigo.split("func vista", 1)[1].split("func postergar", 1)[0]
        self.assertIn('"estado": "pospuesta" if esta_pospuesta', bloque)
        self.assertIn('"texto": historia["texto"]', bloque)
        self.assertIn('"opciones": historia["opciones"]', bloque)

    def test_resolver_limpia_la_marca_pospuesta(self):
        bloque = self.codigo.split("func resolver", 1)[1].split("func cargas", 1)[0]
        self.assertIn("_quitar_pospuesta(estado, carta_id)", bloque)
        self.assertIn("historias[carta_id] = eje", bloque)

    def test_posponer_es_idempotente_y_determinista(self):
        bloque = self.codigo.split("func postergar", 1)[1].split("func esta_pospuesta", 1)[0]
        self.assertIn("if not pospuestas.has(carta_id)", bloque)
        self.assertIn("pospuestas.sort()", bloque)
        self.assertNotIn("RandomNumberGenerator", self.codigo)

    def test_posponer_no_reduce_pendientes(self):
        bloque = self.codigo.split("func pendientes", 1)[1].split("func _pospuestas", 1)[0]
        self.assertIn('estado.get("historias_cartas", {})', bloque)
        self.assertNotIn("historias_pospuestas", bloque)


if __name__ == "__main__":
    unittest.main()
