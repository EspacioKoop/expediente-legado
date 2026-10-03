from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ADAPTADOR = (
    ROOT / "godot/guion/juicio_combate_arconte_host_3d.gd"
).read_text(encoding="utf-8")


class ArconteHost2093Test(unittest.TestCase):
    def test_monta_controlador_y_presentacion_existentes(self):
        self.assertIn("JuicioCombateArquetipos.CONTROLADOR", ADAPTADOR)
        self.assertIn("JuicioCombateArquetipos.nuevo(", ADAPTADOR)
        self.assertIn("JuicioCombateArconte3D.montar_zonas", ADAPTADOR)
        self.assertIn('"_variante_onirica": VARIANTE', ADAPTADOR)

    def test_avance_delega_sin_duplicar_politica(self):
        self.assertIn("JuicioCombateArconte3D", ADAPTADOR)
        self.assertIn(". avanzar(", ADAPTADOR)
        self.assertIn('salida.get("unidad", unidad)', ADAPTADOR)
        self.assertIn('"inicio_marca"', ADAPTADOR)
        self.assertIn('"inicio_zona"', ADAPTADOR)
        self.assertIn('"zona_activa"', ADAPTADOR)
        self.assertIn('"abrir_ventana"', ADAPTADOR)
        self.assertIn('"geometria"', ADAPTADOR)

    def test_zonas_activas_proceden_del_estado_mecanico(self):
        self.assertIn("JuicioCombateArquetipos.ACTIVAR_ZONA", ADAPTADOR)
        self.assertIn("var zonas_activas :=", ADAPTADOR)
        self.assertNotIn(".visible", ADAPTADOR)
        self.assertNotIn("material_override", ADAPTADOR)

    def test_salida_valida_es_dato_del_host(self):
        self.assertIn("queda_salida_valida: bool = true", ADAPTADOR)
        self.assertIn("queda_salida_valida,", ADAPTADOR)
        for inferencia in ("Navigation", "raycast", "intersect", "get_world_3d"):
            self.assertNotIn(inferencia, ADAPTADOR)

    def test_reduccion_movimiento_solo_llega_a_presentacion(self):
        inicio = ADAPTADOR.index("static func avanzar(")
        bloque = ADAPTADOR[inicio:]
        self.assertEqual(2, bloque.count("reduccion_movimiento"))
        presentacion = bloque.index("JuicioCombateArconte3D.presentacion")
        self.assertGreater(bloque.index("reduccion_movimiento", presentacion), presentacion)

    def test_no_crea_autoridad_paralela(self):
        for prohibido in (
            "Partida.",
            "Jornada.",
            "SuenoCombate.",
            "resultado_ataque_rival",
            "_aplicar_impacto_rival",
            "loot",
            "XP",
            "ReligionEventos",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, ADAPTADOR)


if __name__ == "__main__":
    unittest.main()
