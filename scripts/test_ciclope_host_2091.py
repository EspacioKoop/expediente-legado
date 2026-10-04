from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"
CICLOPE = (GUION / "juicio_combate_ciclope_host_3d.gd").read_text(encoding="utf-8")
ROUTER = (GUION / "juicio_combate_variante_host_3d.gd").read_text(encoding="utf-8")
HOST = (GUION / "juicio_combate_3d.gd").read_text(encoding="utf-8")


class CiclopeHost2091Test(unittest.TestCase):
    def test_reutiliza_embestidor_y_presentacion_sin_politica_paralela(self):
        self.assertIn('const VARIANTE := "ciclope_cantera"', CICLOPE)
        self.assertIn("ARQUETIPOS.nuevo(ARQUETIPOS.EMBESTIDOR", CICLOPE)
        self.assertRegex(CICLOPE, r"RUNTIME\s*\.\s*avanzar\(")
        self.assertRegex(CICLOPE, r"RUNTIME\s*\.\s*mover\(")
        self.assertRegex(CICLOPE, r"RUNTIME\s*\.\s*pintar_linea\(")
        self.assertIn("PRESENTACION.montar(", CICLOPE)
        self.assertRegex(CICLOPE, r"PRESENTACION\s*\.\s*pintar\(")

    def test_carga_conserva_rumbo_y_choque_pasa_por_impacto_comun(self):
        self.assertIn('unidad.get("rumbo_bloqueado", rival.rotation.y)', CICLOPE)
        self.assertIn("JuicioCombateArquetipoHost.direccion_linea(rumbo)", CICLOPE)
        self.assertIn("REGLAS.limitar_a_arena(", CICLOPE)
        self.assertRegex(CICLOPE, r"REGLAS\s*\.\s*resultado_ataque_rival\(")
        self.assertIn('anfitrion.call("_aplicar_impacto_rival", resultado)', CICLOPE)
        self.assertIn('"impacto_carga_emitido": false', CICLOPE)
        self.assertIn('estado["impacto_carga_emitido"] = true', CICLOPE)

    def test_router_despacha_ciclope_y_bloquea_movimiento_clasico(self):
        self.assertIn("JuicioCombateCiclopeHost3D.VARIANTE", ROUTER)
        self.assertIn("JuicioCombateCiclopeHost3D.montar(", ROUTER)
        self.assertIn("JuicioCombateCiclopeHost3D.es_estado(estado)", ROUTER)
        self.assertIn("JuicioCombateCiclopeHost3D.avanzar(", ROUTER)
        movimiento = ROUTER.split("static func controla_movimiento(", 1)[1]
        self.assertIn("or JuicioCombateCiclopeHost3D.es_estado(estado)", movimiento)
        self.assertNotIn("JuicioCombateCiclopeHost3D", HOST)

    def test_no_adquiere_seleccion_cultural_ni_consecuencias(self):
        for prohibido in (
            "ReligionEventos",
            "CombateContextual",
            "Partida.",
            "Jornada.",
            "SuenoCombate.",
            "loot",
            "XP",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, CICLOPE)


if __name__ == "__main__":
    unittest.main()
