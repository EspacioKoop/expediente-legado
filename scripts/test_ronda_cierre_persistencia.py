from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
JORNADA = (ROOT / "godot/guion/jornada.gd").read_text(encoding="utf-8")
RONDA = (ROOT / "godot/guion/ronda_cierre.gd").read_text(encoding="utf-8")
PARTIDA = (ROOT / "godot/guion/partida.gd").read_text(encoding="utf-8")


class RondaCierrePersistenciaTest(unittest.TestCase):
    def test_jornada_declara_estado_persistible_vacio(self):
        self.assertIn('"ronda_cierre": {}', JORNADA)

    def test_inicializacion_es_idempotente_y_derivada(self):
        bloque = JORNADA.split("static func asegurar_ronda_cierre", 1)[1].split(
            "## Dormir:", 1
        )[0]
        self.assertIn('jornada.get("ronda_cierre", {})', bloque)
        self.assertIn('actual.get("dia", 0)', bloque)
        self.assertIn('jornada.get("dia", 1)', bloque)
        self.assertIn('jornada.get("raiz", 0)', bloque)
        self.assertIn("RondaCierre.nueva(", bloque)
        self.assertIn('jornada["ronda_cierre"] = creada', bloque)

    def test_dia_nuevo_limpia_solo_la_ronda_diaria(self):
        bloque = JORNADA.split("static func despertar(", 1)[1].split(
            "static func gastar_sueno", 1
        )[0]
        self.assertIn('jornada["ronda_cierre"] = {}', bloque)

    def test_reasignacion_reutiliza_nueva_y_por_tanto_reinicia_la_ronda(self):
        bloque = JORNADA.split("static func reiniciar_vuelta", 1)[1]
        self.assertIn("var nueva_vida := nueva(", bloque)
        self.assertIn("for clave in nueva_vida:", bloque)

    def test_partida_valida_el_fragmento_de_ronda(self):
        bloque = PARTIDA.split("static func _validar_jornada", 1)[1].split(
            "static func _entero_valido", 1
        )[0]
        self.assertIn('jornada.has("ronda_cierre")', bloque)
        self.assertIn("RondaCierre.validar", bloque)

    def test_validador_rechaza_rutas_imposibles_y_progreso_ajeno(self):
        self.assertIn("static func validar", RONDA)
        self.assertIn("ruta contiene duplicados", RONDA)
        self.assertIn("ruta contiene punto inválido", RONDA)
        self.assertIn("completados contiene punto inválido", RONDA)

    def test_persistencia_no_concede_sellos_ni_toca_balance(self):
        for texto in (JORNADA, RONDA, PARTIDA):
            self.assertNotIn('registrar_sello(estado, "planta-en-orden")', texto)
        bloque = JORNADA.split("static func asegurar_ronda_cierre", 1)[1].split(
            "## Dormir:", 1
        )[0]
        for prohibido in ("dinero", "acciones", "pistas_descubiertas", "vida"):
            self.assertNotIn(prohibido, bloque)


if __name__ == "__main__":
    unittest.main()
