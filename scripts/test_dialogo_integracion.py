from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
CLIMA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class DialogoIntegracionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.clima = CLIMA.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_integra_dialogo_sin_cambiar_raiz_ni_herencia(self):
        self.assertIn('res://guion/dia_clima_app.gd', self.escena)
        self.assertIn('extends "res://guion/dia_calle_app.gd"', self.clima)

    def test_intervencion_real_usa_dialogo_diegetico(self):
        self.assertIn('salida.get_meta("frase", "")', self.clima)
        self.assertIn("DialogoDiegetico.mostrar", self.clima)
        self.assertIn("_hud", self.clima)
        self.assertIn("_mundo", self.clima)
        self.assertIn("_caminante", self.clima)

    def test_guardado_y_pantallas_siguen_en_la_capa_base(self):
        self.assertIn("partida.guardado_pendiente", self.clima)
        self.assertIn("_pantalla != null", self.clima)
        self.assertGreaterEqual(self.clima.count("super._al_pisar_salida"), 3)

    def test_no_duplica_contenido_ni_estado(self):
        for prohibido in (
            "Companeros.frase_de",
            "Partida.guardar",
            "pistas_descubiertas",
            "_nomina.text",
        ):
            self.assertNotIn(prohibido, self.clima)

        # #963 integra aquí únicamente el reloj transversal; no debe convertir
        # esta capa en propietaria de las demás reglas de Jornada.
        usos_jornada = set(re.findall(r"\bJornada\.([A-Za-z_]\w*)", self.clima))
        self.assertIn("hora_decimal", usos_jornada)
        self.assertLessEqual(usos_jornada, {"hora_decimal", "sincronizar_reloj_fase"})


if __name__ == "__main__":
    unittest.main()
