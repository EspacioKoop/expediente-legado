"""Checks for the original 3D opening montage after the Eliot/Dylan cards.

These are structural regression checks, not a replacement for a visual playtest.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MONTAGE = ROOT / "godot/guion/apertura_onirica_cinematica.gd"
INTRO = ROOT / "godot/guion/inicio_app.gd"
PLAYER = ROOT / "godot/guion/cinematica_app.gd"


class OpeningMontageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.montage = MONTAGE.read_text(encoding="utf-8")
        cls.intro = INTRO.read_text(encoding="utf-8")
        cls.player = PLAYER.read_text(encoding="utf-8")

    def test_uses_existing_3d_sets_not_placeholder_2d_shapes(self):
        for snippet in ("EspaciosCatalogo.OFICINA", "EspaciosCatalogo.CALLE",
                        "EspaciosCatalogo.CASA", '"tipo": "3d"',
                        '"decorado": decorado', '"camara_desde": desde',
                        '"mira_desde": mira_desde'):
            self.assertIn(snippet, self.montage)
        self.assertNotIn('"tipo": "2d"', self.montage)

    def test_24_original_shots_with_durations_70_to_110_seconds(self):
        shots = re.findall(r'_agregar\(\s*tomas,\s*"([^"]+)",\s*"[^"]*",\s*'
                           r'"(oficina|calle|casa)",\s*([\d.]+)', self.montage, re.M)
        self.assertEqual(len(shots), 24)
        self.assertGreaterEqual(sum(float(t) for _, _, t in shots), 70)
        self.assertLessEqual(sum(float(t) for _, _, t in shots), 110)
        self.assertEqual({place for _, place, _ in shots}, {"oficina", "calle", "casa"})

    def test_black_transitions_and_lens_choices(self):
        for token in ('"fundido_desde"', '"fundido_hasta"', '"fov"', 'Vector3'):
            self.assertIn(token, self.montage)
        self.assertIn('fundido_desde: float = 0.0', self.montage)
        self.assertIn('fundido_hasta: float = 0.0', self.montage)

    def test_epigraphs_montage_credits_menu_order(self):
        start = self.intro.index("func _iniciar_apertura_creditos")
        montage = self.intro.index("func _iniciar_montaje_onirico")
        credits = self.intro.index("func _iniciar_cinematica_creditos")
        complete = self.intro.index("func _terminar_apertura_creditos")
        self.assertLess(start, montage)
        self.assertLess(montage, credits)
        self.assertIn('epigrafes.terminada.connect(_iniciar_montaje_onirico)', self.intro)
        self.assertIn('reproductor.terminada.connect(_iniciar_cinematica_creditos)', self.intro)
        self.assertIn('app.terminada.connect(_terminar_apertura_creditos)', self.intro)
        self.assertIn('CreditosInicioCinematica.planos()', self.intro)
        self.assertIn('_enfocar_menu_inicial()', self.intro)
        self.assertGreater(complete, credits)

    def test_skip_and_reduce_motion_in_common_cinematic_player(self):
        self.assertIn('func saltar()', self.player)
        self.assertIn('configurar_reduccion_movimiento', self.intro)
        self.assertIn('_reduccion_movimiento', self.player)
        self.assertIn('if is_instance_valid(_montaje_onirico):', self.intro)
        self.assertIn('_montaje_onirico.call("saltar")', self.intro)
        self.assertIn('if tomas.is_empty():', self.intro)

    def test_original_text_not_copyrighted_media(self):
        self.assertNotIn("Lain", self.montage)
        self.assertNotIn("Evangelion", self.montage)
        self.assertNotIn("Paranoia Agent", self.montage)
        self.assertIn("No cita escenas ni", self.montage)


if __name__ == "__main__":
    unittest.main()
