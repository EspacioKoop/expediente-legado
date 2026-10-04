from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SELECTOR = (
    ROOT / "godot/guion/juicio_combate_variante_onirica.gd"
).read_text(encoding="utf-8")


class VarianteOnirica2093Test(unittest.TestCase):
    def test_arconte_solo_entra_por_controlador_en_sueno(self):
        self.assertIn('const ARCONTE_UMBRAL := "arconte_umbral"', SELECTOR)
        self.assertIn("if plano != CombateContextual.PLANO_SUENO:", SELECTOR)
        self.assertIn(
            "if arquetipo == JuicioCombateArquetipos.CONTROLADOR:",
            SELECTOR,
        )
        self.assertIn(
            "return ARCONTE_UMBRAL if _hay_exposicion_arconte(registro, dia) else",
            SELECTOR,
        )

    def test_gate_exige_exposicion_y_referencia_documental_exacta(self):
        helper = SELECTOR.split(
            "static func _hay_exposicion_arconte(", 1
        )[1]
        self.assertIn("ReligionEventos.CANAL_EXPOSICION", helper)
        self.assertIn('const TRADICION_GNOSTICA := "gnosticismo"', SELECTOR)
        self.assertIn(
            'const CONTEXTO_ARCONTE := "nag_hammadi:ii_4:hypostasis_archons"',
            SELECTOR,
        )
        self.assertIn('valor.get("tradicion", "")', helper)
        self.assertIn('valor.get("contexto", "")', helper)
        self.assertIn("tradicion == TRADICION_GNOSTICA", helper)
        self.assertIn("contexto == CONTEXTO_ARCONTE", helper)
        self.assertIn('valor.get("jornada", -1)', helper)

    def test_arconte_no_acepta_otros_canales_ni_infiere_conviccion(self):
        helper = SELECTOR.split(
            "static func _hay_exposicion_arconte(", 1
        )[1]
        for prohibido in (
            "CANAL_PRACTICA",
            "CANAL_VINCULO",
            "CANAL_CONVICCION",
            "ultima_declaracion",
            "declaracion",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, helper)

    def test_gargola_conserva_sus_tres_canales(self):
        helper = SELECTOR.split(
            "static func _hay_exposicion_gargola(", 1
        )[1].split("static func _hay_exposicion_arconte(", 1)[0]
        for canal in (
            "CANAL_EXPOSICION",
            "CANAL_PRACTICA",
            "CANAL_VINCULO",
        ):
            with self.subTest(canal=canal):
                self.assertIn(canal, helper)
        self.assertIn(
            "if arquetipo == JuicioCombateArquetipos.BLOQUEADOR:",
            SELECTOR,
        )

    def test_selector_no_registra_hechos_ni_toca_autoridades(self):
        for prohibido in (
            "ReligionEventos.registrar(",
            "ReligionEventos.crear_evento(",
            "Partida.",
            "Jornada.",
            "_aplicar_impacto",
            "resultado_ataque_rival",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, SELECTOR)


if __name__ == "__main__":
    unittest.main()
