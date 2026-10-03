from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WIRING = (
    ROOT / "godot/guion/juicio_combate_arconte_wiring_3d.gd"
).read_text(encoding="utf-8")
ADAPTADOR = (
    ROOT / "godot/guion/juicio_combate_arconte_host_3d.gd"
).read_text(encoding="utf-8")
ROUTER = (
    ROOT / "godot/guion/juicio_combate_variante_host_3d.gd"
).read_text(encoding="utf-8")


class ArconteWiring2220Test(unittest.TestCase):
    def test_montaje_reutiliza_adaptador_existente(self):
        self.assertIn("const ARCONTE = preload(", WIRING)
        self.assertIn("ARCONTE.nuevo(anfitrion, raiz)", WIRING)
        self.assertIn("const VARIANTE := ARCONTE.VARIANTE", WIRING)
        self.assertNotIn("JuicioCombateArquetipos.nuevo", WIRING)

    def test_tick_delega_en_controlador_y_no_duplica_politica(self):
        self.assertIn("ARCONTE.avanzar(", WIRING)
        self.assertIn('bool(paso.get("zona_activa", false))', WIRING)
        self.assertIn('bool(paso.get("inicio_marca", false))', WIRING)
        self.assertIn('bool(paso.get("abrir_ventana", false))', WIRING)
        for duplicado in (
            "MARCAR_ZONA",
            "ACTIVAR_ZONA",
            "RECUPERAR",
            "CONTROLADOR_TELEGRAFO",
            "CONTROLADOR_ZONA",
        ):
            with self.subTest(duplicado=duplicado):
                self.assertNotIn(duplicado, WIRING)

    def test_impacto_es_unico_por_activacion_y_usa_autoridad_comun(self):
        self.assertIn('estado["_impacto_zona_emitido"] = false', WIRING)
        self.assertIn('not bool(estado.get("_impacto_zona_emitido", false))', WIRING)
        self.assertIn('estado["_impacto_zona_emitido"] = true', WIRING)
        self.assertIn("REGLAS.resultado_ataque_rival(", WIRING)
        self.assertIn('anfitrion.call("_aplicar_impacto_rival", resultado)', WIRING)
        self.assertNotIn("_determinacion_jugador", WIRING)
        self.assertNotIn("_terminar(", WIRING)

    def test_geometria_activa_es_consulta_fisica_local(self):
        self.assertIn("static func _contiene(", WIRING)
        self.assertIn('geometria.get("origen"', WIRING)
        self.assertIn('geometria.get("rumbo"', WIRING)
        self.assertIn('geometria.get("largo"', WIRING)
        self.assertIn('geometria.get("ancho"', WIRING)
        for prohibido in ("Navigation", "PhysicsDirectSpaceState", "intersect_ray", "RayCast3D"):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, WIRING)

    def test_adaptador_puro_sigue_sin_dano(self):
        self.assertNotIn("_aplicar_impacto_rival", ADAPTADOR)
        self.assertNotIn("resultado_ataque_rival", ADAPTADOR)
        self.assertNotIn("Partida.", ADAPTADOR)
        self.assertNotIn("Jornada.", ADAPTADOR)

    def test_router_no_decide_cultura_ni_dano(self):
        self.assertIn("JuicioCombateArconteWiring3D", ROUTER)
        for prohibido in (
            "ReligionEventos",
            "CombateContextual",
            "_aplicar_impacto_rival",
            "resultado_ataque_rival",
            "Partida.",
            "Jornada.",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, ROUTER)


if __name__ == "__main__":
    unittest.main()
