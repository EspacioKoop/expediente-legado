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

    def test_posponer_acumula_reintentos_y_sigue_siendo_determinista(self):
        bloque = self.codigo.split("func postergar", 1)[1].split("func esta_pospuesta", 1)[0]
        self.assertIn("if not pospuestas.has(carta_id)", bloque)
        self.assertIn("pospuestas.sort()", bloque)
        self.assertIn("int(conteos.get(carta_id, 0)) + 1", bloque)
        self.assertIn("CLAVE_CONTEO_POSPUESTAS", bloque)
        self.assertIn("_registrar_historial", bloque)
        self.assertNotIn("RandomNumberGenerator", self.codigo)

    def test_expone_presion_sin_modificar_opciones(self):
        bloque = self.codigo.split("func presion_indecision", 1)[1].split("func historial", 1)[0]
        self.assertIn("UMBRAL_REITERACION", bloque)
        self.assertIn("UMBRAL_ACUMULACION", bloque)
        self.assertIn('"nivel"', bloque)
        self.assertNotIn("opciones", bloque)

    def test_historial_guarda_contexto_y_migra_partidas_anteriores(self):
        bloque = self.codigo.split("func historial", 1)[1].split("func resolver", 1)[0]
        self.assertIn('"legado": true', bloque)
        registrar = self.codigo.split("func _registrar_historial", 1)[1].split("func _quitar_pospuesta", 1)[0]
        for campo in ['"dia"', '"vuelta"', '"fase"', '"posposiciones"']:
            self.assertIn(campo, registrar)

    def test_posponer_no_reduce_pendientes(self):
        bloque = self.codigo.split("func pendientes", 1)[1].split("func _pospuestas", 1)[0]
        self.assertIn('estado.get("historias_cartas", {})', bloque)
        self.assertNotIn("historias_pospuestas", bloque)


if __name__ == "__main__":
    unittest.main()
