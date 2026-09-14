import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULO = ROOT / "godot" / "guion" / "reconstruccion_expediente.gd"
CASOS = ROOT / "godot" / "datos" / "casos.json"


class ReconstruccionExpedienteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MODULO.read_text(encoding="utf-8")
        cls.casos = json.loads(CASOS.read_text(encoding="utf-8"))["casos"]

    def test_deriva_tarjetas_de_registros_sin_catalogo_paralelo(self):
        for campo in ['"id"', '"tipo"', '"folio"', '"fecha"']:
            self.assertIn(campo, self.texto)
        self.assertIn('caso.get("registros", [])', self.texto)
        self.assertNotIn("casos.json", self.texto.split("class_name", 1)[1])

    def test_catalogo_real_tiene_material_cronologico(self):
        self.assertGreater(len(self.casos), 0)
        registros = [registro for caso in self.casos for registro in caso.get("registros", [])]
        self.assertGreater(len(registros), 0)
        self.assertTrue(all(registro.get("id") for registro in registros))
        self.assertTrue(all("fecha" in registro for registro in registros))

    def test_distingue_los_tres_resultados_del_issue(self):
        self.assertIn('COMPATIBLE := "orden_compatible"', self.texto)
        self.assertIn('CONTRADICCION := "contradiccion"', self.texto)
        self.assertIn('DATO_AUSENTE := "dato_ausente"', self.texto)

    def test_admite_secuencia_parcial_y_filtro_de_documentos_visibles(self):
        self.assertIn("visibles: Array = []", self.texto)
        self.assertIn("if not filtro.is_empty()", self.texto)
        self.assertIn('"cobertura": cobertura', self.texto)

    def test_no_modifica_sistemas_de_juego(self):
        bloque = self.texto.lower()
        for termino in [
            "partida.",
            "acusacion",
            "combate",
            "jornada.",
            "dinero",
            "acciones",
            "vida",
            "veredicto",
            "pistas_descubiertas",
        ]:
            self.assertNotIn(termino, bloque)

    def test_orden_compatible_sale_de_fecha_y_desempata_por_id(self):
        self.assertIn('return fecha_a < fecha_b', self.texto)
        self.assertIn('return String(a.get("id", "")) < String(b.get("id", ""))', self.texto)

    def test_declara_rangos_burocraticos(self):
        self.assertIn('RANGO_INCOMPLETO := "incompleto"', self.texto)
        self.assertIn('RANGO_CONSISTENTE := "consistente"', self.texto)
        self.assertIn('RANGO_EJEMPLAR := "ejemplar"', self.texto)


if __name__ == "__main__":
    unittest.main()
