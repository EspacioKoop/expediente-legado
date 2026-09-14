from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIMA = ROOT / "godot" / "guion" / "clima.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class ClimaDiarioTest(unittest.TestCase):
    def setUp(self):
        self.clima = CLIMA.read_text(encoding="utf-8")
        self.dia = DIA.read_text(encoding="utf-8")
        self.escena = ESCENA.read_text(encoding="utf-8")

    def test_dia_uno_es_despejado_explicito(self):
        self.assertIn('if dia <= 1:', self.clima)
        self.assertIn('return DESPEJADO', self.clima)

    def test_la_rueda_no_usa_azar_ni_estado_guardado(self):
        self.assertIn('RUEDA[(dia - 2) % RUEDA.size()]', self.clima)
        self.assertNotIn('rand', self.clima.lower())
        self.assertNotIn('partida', self.clima.lower())

    def test_solo_el_trayecto_se_declara_exterior(self):
        self.assertIn('if fase == "trayecto":', self.dia)
        self.assertIn('espacio["exterior"] = true', self.dia)
        self.assertIn('if not bool(espacio.get("exterior", false)):', self.dia)

    def test_lluvia_y_nieve_son_particulas_precalculadas(self):
        self.assertIn('GPUParticles3D.new()', self.dia)
        self.assertIn('particulas.preprocess = particulas.lifetime', self.dia)
        self.assertIn('_montar_precipitacion(false)', self.dia)
        self.assertIn('_montar_precipitacion(true)', self.dia)

    def test_no_hay_efectos_mecanicos(self):
        for forbidden in ['dinero', 'acciones', 'velocidad', 'gastar(', 'guardar(']:
            self.assertNotIn(forbidden, self.dia)

    def test_la_escena_activa_la_capa_de_clima(self):
        self.assertIn('path="res://guion/dia_clima_app.gd"', self.escena)


if __name__ == "__main__":
    unittest.main()
