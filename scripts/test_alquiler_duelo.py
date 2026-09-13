from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGLAS = ROOT / "godot" / "guion" / "alquiler_duelo_reglas.gd"
PANTALLA = ROOT / "godot" / "guion" / "alquiler_duelo.gd"
DIA = ROOT / "godot" / "guion" / "dia_alquiler_app.gd"


class AlquilerDueloTest(unittest.TestCase):
    def test_frecuencia_es_un_quinto_y_no_aparece_en_el_primer_alquiler(self) -> None:
        codigo = REGLAS.read_text(encoding="utf-8")
        self.assertIn("const UNO_DE_CADA := 5", codigo)
        self.assertIn("const PRIMER_VENCIMIENTO_CON_DUELO := 2", codigo)
        self.assertIn("tirada % UNO_DE_CADA == 0", codigo)
        self.assertIn('Azar.derivar(', codigo)
        self.assertNotIn("randomize()", codigo)
        self.assertNotIn("randi()", codigo)
        self.assertNotIn("randf()", codigo)

    def test_decision_se_deriva_de_semilla_vuelta_y_numero_de_alquiler(self) -> None:
        codigo = REGLAS.read_text(encoding="utf-8")
        self.assertIn('int(jornada.get("raiz", 0))', codigo)
        self.assertIn('int(jornada.get("vuelta", 1))', codigo)
        self.assertIn("numero, INDICE_EVENTO", codigo)
        self.assertIn("Jornada.alquiler_pendiente(jornada)", codigo)

    def test_ganar_resuelve_sin_cobrar_y_perder_reutiliza_impago(self) -> None:
        codigo = REGLAS.read_text(encoding="utf-8")
        resolver = codigo.split("static func resolver", 1)[1]
        self.assertIn('jornada["alquiler"]["ultimo_resuelto"] = vencimiento', resolver)
        self.assertIn('jornada["alquiler"]["bonificados"]', resolver)
        self.assertIn('jornada["alquiler"]["impagos"]', resolver)
        self.assertIn('"importe": 0 if gano else Jornada.PRECIO_ALQUILER', resolver)
        self.assertNotIn('jornada["dinero"] -=', resolver)
        self.assertNotIn("Jornada.gastar", resolver)
        self.assertIn('jornada["acciones"] -= 1', resolver)

    def test_mostrador_decide_duelo_antes_del_pago_normal(self) -> None:
        codigo = DIA.read_text(encoding="utf-8")
        pagar = codigo.split("func _pagar_alquiler()", 1)[1].split("func _abrir_duelo_alquiler", 1)[0]
        self.assertLess(pagar.index("AlquilerDueloReglas.ocurre"), pagar.index("Jornada.pagar_alquiler"))
        self.assertIn("_abrir_duelo_alquiler()", pagar)
        self.assertIn("AlquilerDueloReglas.resolver(jornada, gano)", codigo)
        self.assertIn("_perder_vivienda()", codigo)

    def test_pantalla_reutiliza_combate_reactivo_y_controles_con_foco(self) -> None:
        codigo = PANTALLA.read_text(encoding="utf-8")
        self.assertIn('Combate.nuevo("reactiva"', codigo)
        self.assertIn("Combate.jugar", codigo)
        self.assertIn("Ventanilla.DE_OFICIO", codigo)
        self.assertIn("grab_focus()", codigo)
        self.assertIn("Button.new()", codigo)
        for token in ("KEY_", "InputEventKey", "is_key_pressed", "randomize()"):
            self.assertNotIn(token, codigo)

    def test_cierre_no_reasigna_ni_pierde_vida_laboral(self) -> None:
        codigo = DIA.read_text(encoding="utf-8")
        cierre = codigo.split("func _cerrar_duelo_alquiler", 1)[1]
        for token in ("_reasignar", "perder_vida", "Acusacion.perder_vida"):
            self.assertNotIn(token, cierre)


if __name__ == "__main__":
    unittest.main()
