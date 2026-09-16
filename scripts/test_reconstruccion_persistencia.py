from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PARTIDA = (ROOT / "godot" / "guion" / "partida.gd").read_text(encoding="utf-8")
RECONSTRUCCION = (ROOT / "godot" / "guion" / "reconstruccion_expediente.gd").read_text(
    encoding="utf-8"
)


class ReconstruccionPersistenciaTest(unittest.TestCase):
    def test_partida_declara_y_valida_reconstrucciones(self):
        self.assertIn('"reconstrucciones": {}', PARTIDA)
        bloque_validacion = PARTIDA.split("static func validar", 1)[1]
        self.assertIn('"reconstrucciones"', bloque_validacion)
        self.assertIn("typeof(guardado[clave]) != TYPE_DICTIONARY", bloque_validacion)

    def test_partidas_antiguas_migran_la_clave_desde_nueva(self):
        fusion = PARTIDA.split("func _fusionar", 1)[1]
        self.assertIn("var fusionado := nueva()", fusion)
        self.assertIn("for clave in fusionado", fusion)
        self.assertIn("if guardado.has(clave)", fusion)

    def test_motor_guarda_un_resumen_y_no_documentos(self):
        bloque = RECONSTRUCCION.split("static func guardar_mejor", 1)[1].split(
            "static func mejor_guardado", 1
        )[0]
        for campo in ('"orden"', '"puntuacion"', '"cobertura"', '"rango"'):
            self.assertIn(campo, bloque)
        for campo in ('"folio"', '"fecha"', '"tipo"'):
            self.assertNotIn(campo, bloque)

    def test_un_intento_peor_no_sobrescribe_el_mejor(self):
        self.assertIn("static func _es_mejor", RECONSTRUCCION)
        self.assertIn("return puntuacion_nueva > puntuacion_actual", RECONSTRUCCION)
        self.assertIn(
            'float(candidato.get("cobertura", 0.0)) > float(actual.get("cobertura", -1.0))',
            RECONSTRUCCION,
        )
        bloque = RECONSTRUCCION.split("static func guardar_mejor", 1)[1]
        self.assertIn("if typeof(actual) != TYPE_DICTIONARY or _es_mejor(candidato, actual)", bloque)
        self.assertIn('"actualizado": false', bloque)

    def test_lectura_devuelve_copia_del_mejor_intento(self):
        bloque = RECONSTRUCCION.split("static func mejor_guardado", 1)[1]
        self.assertIn("mejor.duplicate(true)", bloque)


if __name__ == "__main__":
    unittest.main()
