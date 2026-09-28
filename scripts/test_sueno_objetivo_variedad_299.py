from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_gato_app.gd"
VARIEDAD = ROOT / "godot" / "guion" / "sueno_objetivo_variedad_3d.gd"


class SuenoObjetivoVariedad299Test(unittest.TestCase):
    def setUp(self):
        self.dia = DIA.read_text(encoding="utf-8")
        self.variedad = VARIEDAD.read_text(encoding="utf-8")

    def test_fallback_declara_tres_condiciones_distintas(self):
        for token in (
            "TIPO_RECORRIDO",
            "TIPO_SECUENCIA",
            "TIPO_PERMANENCIA",
            "_tipos_objetivo_sueno",
            "_condicion_objetivo_sueno",
        ):
            self.assertIn(token, self.dia)
        self.assertIn('"condicion": _condicion_objetivo_sueno(tipo)', self.dia)
        self.assertIn('"tipo": tipo', self.dia)

    def test_seleccion_es_determinista_y_no_usa_azar_global(self):
        bloque = self.dia.split("func _tipos_objetivo_sueno()", 1)[1].split("\n\n", 1)[0]
        self.assertIn("to_utf8_buffer()", bloque)
        self.assertIn('jornada.get("dia", 0)', bloque)
        for prohibido in ("randf", "randi", "randomize"):
            self.assertNotIn(prohibido, bloque)

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
