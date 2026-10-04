from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"
ROUTER = (GUION / "juicio_combate_variante_host_3d.gd").read_text(encoding="utf-8")
HOST = (GUION / "juicio_combate_3d.gd").read_text(encoding="utf-8")
MOVIMIENTO = (GUION / "juicio_combate_rival_movimiento_3d.gd").read_text(encoding="utf-8")


class VarianteHost2220Test(unittest.TestCase):
    def test_router_no_decide_seleccion_cultural_ni_dano(self):
        for prohibido in (
            "ReligionEventos",
            "CombateContextual",
            "Partida.",
            "Jornada.",
            "_aplicar_impacto_rival",
            "resultado_ataque_rival",
            "loot",
            "XP",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, ROUTER)

    def test_gargola_conserva_montaje_avance_y_movimiento_propios(self):
        self.assertIn("JuicioCombateGargolaHost3D.VARIANTE", ROUTER)
        self.assertIn("JuicioCombateGargolaHost3D.montar(", ROUTER)
        self.assertIn("JuicioCombateGargolaHost3D.es_estado(estado)", ROUTER)
        self.assertIn("JuicioCombateGargolaHost3D.avanzar(", ROUTER)
        movimiento = ROUTER.split("static func controla_movimiento(", 1)[1]
        self.assertIn("JuicioCombateGargolaHost3D.es_estado(estado)", movimiento)
        self.assertIn("or JuicioCombateArconteWiring3D.es_estado(estado)", movimiento)

    def test_arconte_se_despacha_sin_entrar_en_el_host_principal(self):
        self.assertIn("JuicioCombateArconteWiring3D.VARIANTE", ROUTER)
        self.assertIn("JuicioCombateArconteWiring3D.montar(", ROUTER)
        self.assertIn("JuicioCombateArconteWiring3D.es_estado(estado)", ROUTER)
        self.assertIn("JuicioCombateArconteWiring3D.avanzar(", ROUTER)
        self.assertIn("or JuicioCombateArconteWiring3D.es_estado(estado)", ROUTER)
        self.assertNotIn("JuicioCombateArconteHost3D", HOST)

    def test_tentador_se_despacha_y_posee_su_tick_mimetico(self):
        self.assertIn("JuicioCombateTentadorHost3D.VARIANTE", ROUTER)
        self.assertIn("JuicioCombateTentadorHost3D.montar(", ROUTER)
        self.assertIn("JuicioCombateTentadorHost3D.es_estado(estado)", ROUTER)
        self.assertIn("JuicioCombateTentadorHost3D.avanzar(", ROUTER)
        movimiento = ROUTER.split("static func controla_movimiento(", 1)[1]
        self.assertIn("or JuicioCombateTentadorHost3D.es_estado(estado)", movimiento)
        self.assertNotIn("JuicioCombateTentadorHost3D", HOST)


    def test_variante_desconocida_hace_fallback(self):
        self.assertIn('return {}', ROUTER)
        montar = ROUTER.split("static func montar(", 1)[1].split(
            "static func avanzar(", 1
        )[0]
        self.assertIn('var variante := String(acusado.get("_variante_onirica", ""))', montar)
        self.assertTrue(montar.rstrip().endswith("return {}"))

    def test_host_principal_usa_solo_router_y_gana_margen(self):
        self.assertLess(len(HOST.splitlines()), 1000)
        self.assertIn("JuicioCombateVarianteHost3D.montar(", HOST)
        self.assertIn("JuicioCombateVarianteHost3D.avanzar(", HOST)
        self.assertNotIn("JuicioCombateGargolaHost3D.montar(", HOST)
        self.assertNotIn("JuicioCombateGargolaHost3D.avanzar(", HOST)

    def test_movimiento_consulta_propiedad_de_variante(self):
        self.assertIn(
            "JuicioCombateVarianteHost3D.controla_movimiento(arquetipo)",
            MOVIMIENTO,
        )
        self.assertNotIn("JuicioCombateGargolaHost3D.es_estado(arquetipo)", MOVIMIENTO)


if __name__ == "__main__":
    unittest.main()
