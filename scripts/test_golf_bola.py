from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "golf_bola.gd"


class GolfBolaTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_simulacion_es_standalone_y_determinista(self):
        self.assertIn("class_name GolfBola", self.source)
        self.assertIn("extends RefCounted", self.source)
        self.assertIn("const PASO_FIJO := 1.0 / 120.0", self.source)
        self.assertIn("static func avanzar(estado: Dictionary, delta: float)", self.source)
        self.assertIn("while acumulado >= PASO_FIJO", self.source)
        self.assertNotIn("RigidBody3D", self.source)
        codigo = "\n".join(
            linea
            for linea in self.source.splitlines()
            if not linea.lstrip().startswith("#")
        )
        self.assertNotIn("partida.", codigo.lower())

    def test_tiro_acota_potencia_y_velocidad(self):
        self.assertIn("const VELOCIDAD_MINIMA := 0.30", self.source)
        self.assertIn("const VELOCIDAD_MAXIMA := 2.40", self.source)
        self.assertIn("var fuerza := clampf(potencia, 0.0, 1.0)", self.source)
        self.assertIn(
            "var rapidez := lerpf(VELOCIDAD_MINIMA, VELOCIDAD_MAXIMA, fuerza)",
            self.source,
        )
        self.assertIn('estado["velocidad"] = direccion.normalized() * rapidez', self.source)

    def test_rebotes_se_resuelven_con_limites_simples(self):
        self.assertIn("const REBOTE_PARED := 0.68", self.source)
        self.assertIn("var min_x := limites.position.x + RADIO_BOLA", self.source)
        self.assertIn("var max_x := limites.end.x - RADIO_BOLA", self.source)
        self.assertIn("velocidad.x = absf(velocidad.x) * REBOTE_PARED", self.source)
        self.assertIn("velocidad.x = -absf(velocidad.x) * REBOTE_PARED", self.source)
        self.assertIn("velocidad.y = absf(velocidad.y) * REBOTE_PARED", self.source)
        self.assertIn("velocidad.y = -absf(velocidad.y) * REBOTE_PARED", self.source)

    def test_rozamiento_y_watchdog_garantizan_terminacion(self):
        self.assertIn("const ROZAMIENTO := 0.9", self.source)
        self.assertIn("const VELOCIDAD_REPOSO := 0.025", self.source)
        self.assertIn("const MAX_PASOS := 2400", self.source)
        self.assertIn("rapidez - ROZAMIENTO * PASO_FIJO", self.source)
        self.assertIn('int(estado["pasos"]) >= MAX_PASOS', self.source)
        self.assertIn("static func simular_hasta_detener(estado: Dictionary)", self.source)
        self.assertIn("_forzar_reposo(estado)", self.source)

    def test_posicion_inicial_se_encaja_dentro_del_hoyo(self):
        self.assertIn('"posicion": _encajar(posicion, limites)', self.source)
        self.assertIn("static func _limites_validos(limites: Rect2)", self.source)
        self.assertIn("limites.size.x > diametro", self.source)
        self.assertIn("limites.size.y > diametro", self.source)


if __name__ == "__main__":
    unittest.main()
