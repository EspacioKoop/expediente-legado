from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
IDLE = ROOT / "godot" / "guion" / "companero_idle_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_companeros_idle_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class CompanerosIdleTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.idle = IDLE.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_no_toca_estado_de_juego(self):
        for termino in ("Jornada.", "Partida", "guardar(", "dinero", "acciones"):
            self.assertNotIn(termino, self.idle)

    def test_respira_y_restaura_transform(self):
        self.assertIn("AMPLITUD_RESPIRACION", self.idle)
        self.assertIn("objetivo.scale = _escala_base", self.idle)
        self.assertIn("objetivo.rotation.y = _rotacion_base", self.idle)
        # Sentarse (#134) mueve el cuerpo al asiento; al desmontarse vuelve
        # exactamente a su sitio.
        self.assertIn("objetivo.position = _posicion_original", self.idle)
        self.assertIn("objetivo.rotation.y = _rotacion_original", self.idle)

    def test_reduccion_movimiento_es_preferencia_y_no_jornada(self):
        self.assertIn("PreferenciasSiga.cargar()", self.controller)
        self.assertIn('get("reduccion_movimiento", false)', self.controller)
        self.assertIn("if reduccion_movimiento:", self.idle)
        self.assertIn("actividad_trabajo and not reduccion_movimiento", self.idle)

    def test_controller_solo_monta_en_archivo(self):
        self.assertIn('!= "archivo"', self.controller)
        self.assertIn('OFICINA.get("sitios_companeros", [])', self.controller)
        self.assertIn("Modelos._esqueleto(nodo) != null", self.controller)

    def test_gesto_telefono_es_selectivo(self):
        self.assertIn("telefono := indice == 0", self.controller)
        self.assertIn("if gesto_telefono else 0.0", self.idle)
        self.assertIn("trabajo and not telefono", self.idle)

    def test_actividad_trabajo_es_selectiva_e_intermitente(self):
        self.assertIn("indice > 0 and indice % 2 == 1", self.controller)
        self.assertIn("DURACION_TRABAJO", self.idle)
        self.assertIn("DURACION_PAUSA", self.idle)
        self.assertIn('"work" if _trabajando else "idle"', self.idle)
        self.assertIn("_reloj_actividad = fmod", self.idle)

    def test_dia_monta_controller_hijo(self):
        self.assertIn("dia_companeros_idle_app.gd", self.dia)
        self.assertIn("CompanerosIdleController", self.dia)


if __name__ == "__main__":
    unittest.main()
