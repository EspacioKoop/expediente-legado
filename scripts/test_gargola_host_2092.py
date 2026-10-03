from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"
DIA = (GUION / "dia_combate_contextual_app.gd").read_text(encoding="utf-8")
HOST = (GUION / "juicio_combate_3d.gd").read_text(encoding="utf-8")
GARGOLA = (GUION / "juicio_combate_gargola_host_3d.gd").read_text(encoding="utf-8")
SELECTOR = (GUION / "juicio_combate_variante_onirica.gd").read_text(encoding="utf-8")
MOVIMIENTO = (GUION / "juicio_combate_rival_movimiento_3d.gd").read_text(encoding="utf-8")
ROUTER = (GUION / "juicio_combate_variante_host_3d.gd").read_text(encoding="utf-8")


class GargolaHost2092Test(unittest.TestCase):
    def test_selector_exige_sueno_bloqueador_y_hecho_observable(self):
        self.assertIn("plano != CombateContextual.PLANO_SUENO", SELECTOR)
        self.assertIn("arquetipo != JuicioCombateArquetipos.BLOQUEADOR", SELECTOR)
        for canal in (
            "ReligionEventos.CANAL_EXPOSICION",
            "ReligionEventos.CANAL_PRACTICA",
            "ReligionEventos.CANAL_VINCULO",
        ):
            self.assertIn(canal, SELECTOR)
        self.assertNotIn("ReligionEventos.CANAL_CONVICCION,", SELECTOR)
        self.assertIn('int(valor.get("jornada", -1)) == dia', SELECTOR)

    def test_contextual_no_muta_objetivo_y_pasa_variante_solo_a_combate(self):
        self.assertIn("var objetivo_combate := objetivo.duplicate(true)", DIA)
        self.assertIn('objetivo_combate["_variante_onirica"] = variante', DIA)
        self.assertIn(". configurar(\n\t\t\tobjetivo_combate,", DIA)
        self.assertIn("_combate.arquetipo_onirico = arquetipo", DIA)

    def test_host_principal_solo_delega_y_sigue_bajo_limite(self):
        self.assertLessEqual(len(HOST.splitlines()), 1000)
        self.assertIn("JuicioCombateVarianteHost3D.montar(", HOST)
        self.assertIn("JuicioCombateVarianteHost3D.avanzar(", HOST)
        self.assertIn("JuicioCombateGargolaHost3D.VARIANTE", ROUTER)
        self.assertIn("JuicioCombateGargolaHost3D.montar(", ROUTER)
        self.assertIn("JuicioCombateGargolaHost3D.avanzar(", ROUTER)

    def test_adaptador_reutiliza_runtime_presentacion_y_impacto_comun(self):
        self.assertIn("JuicioCombateGargolaRuntime2092.nuevo", GARGOLA)
        self.assertIn("JuicioCombateGargolaRuntime2092", GARGOLA)
        self.assertIn(". avanzar(", GARGOLA)
        self.assertIn("JuicioCombateGargola3D.montar", GARGOLA)
        self.assertIn("JuicioCombateGargola3D", GARGOLA)
        self.assertIn(". pintar(", GARGOLA)
        self.assertIn('anfitrion.call("_aplicar_impacto_rival", resultado)', GARGOLA)
        self.assertIn("JuicioCombateEmbestidor3D", GARGOLA)
        self.assertIn(". mover(", GARGOLA)
        for prohibido in ("Partida.", "Jornada.", "SuenoCombate.", "loot", "XP"):
            self.assertNotIn(prohibido, GARGOLA)

    def test_guardia_fuerte_sigue_usando_autoridad_bloqueador_existente(self):
        self.assertIn('"tipo": JuicioCombateArquetipos.BLOQUEADOR', GARGOLA)
        self.assertIn('"estado": JuicioCombateArquetipos.GUARDIA', GARGOLA)
        self.assertIn('anfitrion.get("_guardia_rota")', GARGOLA)
        self.assertIn('anfitrion.set("_guardia_rota", false)', GARGOLA)
        self.assertIn("ARQUETIPO_HOST.golpe", HOST)

    def test_movimiento_clasico_no_compite_con_gargola(self):
        self.assertIn("JuicioCombateVarianteHost3D.controla_movimiento(arquetipo)", MOVIMIENTO)
        self.assertIn("JuicioCombateGargolaHost3D.es_estado(estado)", ROUTER)
        self.assertIn("return", MOVIMIENTO)


if __name__ == "__main__":
    unittest.main()
