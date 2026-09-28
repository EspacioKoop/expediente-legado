from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_gato_app.gd"
VARIEDAD = ROOT / "godot" / "guion" / "sueno_objetivo_variedad_3d.gd"
POLITICA = ROOT / "godot" / "guion" / "sueno_objetivos_variedad.gd"


class SuenoObjetivoVariedad299Test(unittest.TestCase):
    def setUp(self):
        self.dia = DIA.read_text(encoding="utf-8")
        self.variedad = VARIEDAD.read_text(encoding="utf-8")
        self.politica = POLITICA.read_text(encoding="utf-8")

    def test_fallback_declara_tres_condiciones_distintas(self):
        for token in (
            "TIPO_RECORRIDO",
            "TIPO_SECUENCIA",
            "TIPO_PERMANENCIA",
            "SuenoObjetivosVariedad.tipos_para",
            "SuenoObjetivosVariedad.condicion",
        ):
            self.assertIn(token, self.dia)
        self.assertIn('"condicion": SuenoObjetivosVariedad.condicion(tipo)', self.dia)
        self.assertIn('"tipo": tipo', self.dia)

    def test_seleccion_es_determinista_y_no_usa_azar_global(self):
        self.assertIn("static func tipos_para(dia: int, escena_id: String)", self.politica)
        self.assertIn("to_utf8_buffer()", self.politica)
        self.assertIn("dia * 17", self.politica)
        self.assertIn("posmod", self.politica)
        self.assertIn("SuenoObjetivosVariedad.tipos_para", self.dia)
        for prohibido in ("randf", "randi", "randomize"):
            self.assertNotIn(prohibido, self.politica)

    def test_secuencia_y_permanencia_delegan_progreso_en_sueno_objetivos(self):
        self.assertIn("SuenoObjetivoVariedad3D.new()", self.dia)
        self.assertIn("controlador.completado.connect", self.dia)
        self.assertIn("SuenoObjetivos.completar(estado, objetivo_id)", self.dia)
        self.assertIn("_tras_cambio_objetivo(estado, true)", self.dia)

    def test_controlador_es_fisica_sin_segunda_fuente_de_verdad(self):
        self.assertIn("func _physics_process(delta: float)", self.variedad)
        self.assertIn("body_entered.connect", self.variedad)
        self.assertIn("body_exited.connect", self.variedad)
        self.assertIn("TIEMPO_PERMANENCIA", self.variedad)
        self.assertIn("rumbo_cambiado.emit", self.variedad)
        ejecutable = "\n".join(
            linea
            for linea in self.variedad.splitlines()
            if not linea.lstrip().startswith("#")
        )
        for prohibido in (
            "Partida",
            "Jornada",
            "pistas_descubiertas",
            "Economia",
            "SuenoObjetivos.completar",
            "_guardar_o_avisar",
            "InputMap",
        ):
            self.assertNotIn(prohibido, ejecutable)

    def test_contrato_ejecutable_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_sueno_objetivo_variedad_299.gd",
            "Sueño variedad objetivos 299:",
        )


if __name__ == "__main__":
    unittest.main()
