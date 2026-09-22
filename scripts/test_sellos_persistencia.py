from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PARTIDA = (ROOT / "godot/guion/partida.gd").read_text(encoding="utf-8")
DIA = (ROOT / "godot/guion/dia_clima_app.gd").read_text(encoding="utf-8")


class SellosPersistenciaTests(unittest.TestCase):
    def test_partida_incluye_y_valida_sellos(self):
        self.assertIn('"sellos_obtenidos": []', PARTIDA)
        bloque = PARTIDA.split("for clave in [", 1)[1].split("]:", 1)[0]
        self.assertIn('"sueno_vencidos"', bloque)
        self.assertIn('"sellos_obtenidos"', bloque)
        self.assertIn("typeof(guardado[clave]) != TYPE_ARRAY", PARTIDA)

    def test_noche_improductiva_se_decide_antes_de_dormir(self):
        bloque = DIA.split("func _al_pisar_salida", 1)[1].split(
            "func _registrar_noche_improductiva", 1
        )[0]
        self.assertIn('salida.get_meta("destino", "")', bloque)
        self.assertIn('destino == "sueño"', bloque)
        self.assertIn("_registrar_noche_improductiva()", bloque)
        self.assertIn('jornada.get("leido_hoy", []).is_empty()', DIA)
        self.assertIn('int(jornada.get("cerrados_hoy", 0)) != 0', DIA)
        self.assertIn(
            'Sellos.registrar_sello(partida.estado, "noche-improductiva")', DIA
        )

    def test_emisor_no_altera_reglas_de_juego(self):
        bloque = DIA.split("func _registrar_noche_improductiva", 1)[1].split(
            "func _espacio_de", 1
        )[0]
        for prohibido in [
            'jornada["dinero"] =',
            'jornada["acciones"] =',
            'partida.estado["vida"] =',
            'partida.estado["pistas_descubiertas"] =',
            "Jornada.dormir(",
            "partida.guardar(",
        ]:
            self.assertNotIn(prohibido, bloque)

    def test_no_se_crea_contador_paralelo(self):
        self.assertNotIn("noches_improductivas", PARTIDA)
        self.assertNotIn("noches_improductivas", DIA)


if __name__ == "__main__":
    unittest.main()
