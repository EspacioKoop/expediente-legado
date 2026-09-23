from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = json.loads((ROOT / "godot/datos/sellos.json").read_text(encoding="utf-8"))
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
GATO = (ROOT / "godot/guion/dia_gato_app.gd").read_text(encoding="utf-8")
COMBATE = (ROOT / "godot/guion/sueno_combate.gd").read_text(encoding="utf-8")


class SelloDespertarReglamentarioTests(unittest.TestCase):
    def test_catalogo_declara_el_sello(self):
        por_id = {entrada["id"]: entrada for entrada in CATALOGO}
        self.assertIn("despertar-reglamentario", por_id)
        sello = por_id["despertar-reglamentario"]
        self.assertEqual(sello["origen"], "sueno-completado")
        self.assertTrue(sello["disponible"])

    def test_emisor_usa_solo_el_estado_natural_del_sueno(self):
        self.assertIn(
            'const SELLO_DESPERTAR_REGLAMENTARIO := "despertar-reglamentario"',
            DIA,
        )
        bloque = DIA.split("func _registrar_despertar_reglamentario", 1)[1].split(
            "## Reconoce una jornada con trabajo real", 1
        )[0]
        self.assertIn('String(jornada.get("fase", "")) != "sueño"', bloque)
        self.assertIn('jornada.get("sueno_escenas", [])', bloque)
        self.assertIn('jornada.get("sueno_total", 0.0)', bloque)
        self.assertIn("Sellos.registrar_sello", bloque)

    def test_ruta_base_emite_antes_del_despertar_normal(self):
        tramo = DIA.split('match jornada["fase"]:', 1)[1].split(
            "## Reconoce una noche completada", 1
        )[0]
        emisor = "_registrar_despertar_reglamentario()"
        auditoria = "Auditorias.resolver_fin_sueno(partida.estado, true)"
        despertar = "Jornada.despertar(jornada)"
        for llamada in (emisor, auditoria, despertar):
            self.assertIn(llamada, tramo)
        self.assertLess(tramo.index(emisor), tramo.index(auditoria))
        self.assertLess(tramo.index(auditoria), tramo.index(despertar))

    def test_ruta_de_objetivos_emite_antes_del_despertar_normal(self):
        tramo = GATO.split("func _resolver_objetivos_sueno", 1)[1].split(
            "func registrar_objetivo_puzzle_onirico", 1
        )[0]
        emisor = "_registrar_despertar_reglamentario()"
        auditoria = "Auditorias.resolver_fin_sueno(partida.estado, true)"
        despertar = "Jornada.despertar(jornada)"
        for llamada in (emisor, auditoria, despertar):
            self.assertIn(llamada, tramo)
        self.assertLess(tramo.index(emisor), tramo.index(auditoria))
        self.assertLess(tramo.index(auditoria), tramo.index(despertar))

    def test_despertares_forzados_no_emiten(self):
        proceso = DIA.split("func _process(delta: float) -> void:", 1)[1].split(
            "func _guardar_o_avisar", 1
        )[0]
        self.assertIn("Jornada.despertar_de_golpe(jornada)", proceso)
        self.assertNotIn("_registrar_despertar_reglamentario()", proceso)
        self.assertNotIn("_registrar_despertar_reglamentario()", COMBATE)

    def test_emisor_no_toca_balance_ni_fuerza_guardado(self):
        bloque = DIA.split("func _registrar_despertar_reglamentario", 1)[1].split(
            "## Reconoce una jornada con trabajo real", 1
        )[0]
        for prohibido in (
            'jornada["dinero"] =',
            'jornada["acciones"] =',
            'partida.estado["vida"] =',
            'partida.estado["pistas_descubiertas"] =',
            "_guardar_o_avisar(",
            "Jornada.despertar(",
            "Jornada.despertar_de_golpe(",
        ):
            self.assertNotIn(prohibido, bloque)


if __name__ == "__main__":
    unittest.main()
