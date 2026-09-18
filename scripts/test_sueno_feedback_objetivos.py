from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"


class SuenoFeedbackObjetivosTest(unittest.TestCase):
    def setUp(self):
        self.codigo = DIA_GATO.read_text(encoding="utf-8")

    def test_muestra_progreso_desde_cero(self):
        bloque = self.codigo.split("func _montar_objetivos_sueno()", 1)[1].split(
            "func _al_pisar_objetivo", 1
        )[0]
        self.assertIn(
            "_actualizar_feedback_objetivos(SuenoObjetivos.progreso(estado))",
            bloque,
        )
        self.assertIn('marcas.append("◆" if i < progreso.x else "◇")', self.codigo)

    def test_recalcula_guia_tras_cada_objetivo(self):
        bloque = self.codigo.split("func _al_pisar_objetivo", 1)[1].split(
            "func _actualizar_feedback_objetivos", 1
        )[0]
        self.assertIn("_tras_cambio_objetivo(estado, true)", bloque)
        self.assertIn("_actualizar_rumbo_guia_pendiente(estado)", bloque)
        self.assertIn("_orientar_gato_guia()", bloque)

    def test_puzzle_refresca_el_mismo_feedback_sin_doble_guardado(self):
        self.assertIn("_tras_cambio_objetivo(estado, false)", self.codigo)
        self.assertIn("_actualizar_feedback_objetivos(SuenoObjetivos.progreso(estado))", self.codigo)
        self.assertIn("_actualizar_rumbo_guia_pendiente(estado)", self.codigo)

    def test_guia_ignora_objetivos_ya_completados(self):
        bloque = self.codigo.split("func _actualizar_rumbo_guia_pendiente", 1)[1].split(
            "func _orientar_gato_guia", 1
        )[0]
        self.assertIn('completados: Array = estado.get("completados", [])', bloque)
        self.assertIn("not _objetivo_puntuable(estado, objetivo_id)", bloque)
        self.assertIn('_salida_guia = objetivo.get("pos", _entrada_guia)', bloque)

    def test_recarga_no_remonta_la_ruta_sustituida(self):
        montaje = self.codigo.split("func _montar_objetivos_sueno()", 1)[1].split(
            "func _al_pisar_objetivo", 1
        )[0]
        self.assertIn("not _objetivo_puntuable(estado, objetivo_id)", montaje)
        self.assertIn("func _objetivo_puntuable(", self.codigo)
        self.assertIn('objetivo.get("cuenta", true)', self.codigo)

    def test_no_reintroduce_salida_fisica(self):
        self.assertIn('espacio["salidas"] = []', self.codigo)
        self.assertNotIn('destino = "salida"', self.codigo)


if __name__ == "__main__":
    unittest.main()
