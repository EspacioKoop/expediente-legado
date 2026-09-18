import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
BASE = (ROOT / "godot/guion/visor_expediente.gd").read_text(encoding="utf-8")
PROMETEO = (ROOT / "godot/guion/prometeo.gd").read_text(encoding="utf-8")
VISOR = (ROOT / "godot/guion/visor_pronosticos_app.gd").read_text(encoding="utf-8")
RESOLVER = (ROOT / "godot/guion/pronosticos_auditoria.gd").read_text(encoding="utf-8")
PRUEBA_GODOT = "res://pruebas/pruebas_pronosticos_tarot.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class PronosticosTarotTests(unittest.TestCase):
    def test_el_mago_notifica_solo_si_es_hallazgo_nuevo(self):
        inicio = BASE.index("func _sincronizar_tarot_por_pista()")
        fin = BASE.index("## Encontrar una carta escondida", inicio)
        bloque = BASE[inicio:fin]
        self.assertIn(
            "for carta_id in Prometeo.sincronizar_tarot_por_pistas(partida.estado):",
            bloque,
        )
        self.assertIn("_al_carta_desbloqueada(carta_id)", bloque)

        inicio = PROMETEO.index("static func sincronizar_tarot_por_pistas(")
        fin = PROMETEO.index("## Una acusación es precipitada", inicio)
        regla = PROMETEO[inicio:fin]
        self.assertIn(
            'if pistas.size() >= 1 and desbloquear_carta_en_estado(estado, "el-mago"):',
            regla,
        )
        self.assertIn('nuevas.append("el-mago")', regla)

    def test_carta_oculta_notifica_antes_de_guardar(self):
        inicio = BASE.index("func _al_encontrar_carta(")
        fin = BASE.index("func _al_carta_desbloqueada", inicio)
        bloque = BASE[inicio:fin]
        self.assertLess(bloque.index("Prometeo.desbloquear_carta"), bloque.index("_al_carta_desbloqueada"))
        self.assertLess(bloque.index("_al_carta_desbloqueada"), bloque.index("_guardar_o_avisar()"))

    def test_la_capa_de_pronosticos_resuelve_el_hook(self):
        self.assertIn("func _al_carta_desbloqueada(carta_id: String)", VISOR)
        self.assertIn("PronosticosAuditoria.resolver_tarot", VISOR)
        self.assertIn('String(actual.get("tipo", "")) != "tarot"', RESOLVER)

    def test_el_selector_no_deriva_opciones_del_expediente(self):
        inicio = VISOR.index('if tipo == "tarot":')
        fin = VISOR.index('return\n\n\t_pronostico_valor.add_item', inicio)
        bloque = VISOR[inicio:fin]
        self.assertIn('partida.estado.get("tarot", [])', bloque)
        self.assertIn('carta.get("recogida", false)', bloque)
        self.assertNotIn("CartasOcultas", bloque)
        self.assertNotIn('caso.get("pistas"', bloque)
        self.assertNotIn('caso.get("registros"', bloque)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 9, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
