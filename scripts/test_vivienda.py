from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CAPA = RAIZ / "godot" / "guion" / "dia_alquiler_app.gd"
JORNADA = RAIZ / "godot" / "guion" / "jornada.gd"


class ViviendaTest(unittest.TestCase):
    def setUp(self):
        self.capa = CAPA.read_text(encoding="utf-8")
        self.jornada = JORNADA.read_text(encoding="utf-8")

    def test_la_vivienda_sale_del_estado_de_alquiler(self):
        self.assertIn('get("impagos", 0)', self.capa)
        self.assertIn("_impago_inminente()", self.capa)
        self.assertIn('return "oficina"', self.capa)
        self.assertIn('return "casa"', self.capa)

    def test_el_impago_se_decide_al_final_del_trayecto(self):
        self.assertIn('jornada.get("fase", "") == "trayecto"', self.capa)
        self.assertIn('String(salida.get_meta("destino", "")) == "casa"', self.capa)
        self.assertIn('and _impago_inminente()', self.capa)

    def test_el_gato_no_puede_seguir_a_la_oficina(self):
        transito = self.capa.split("func _al_pisar_salida", 1)[1].split("func ", 1)[0]
        perder = self.capa.split("func _perder_vivienda", 1)[1].split("func ", 1)[0]
        self.assertIn("_perder_vivienda()", transito)
        self.assertIn('jornada["gato"]["presente"] = false', perder)
        self.assertLess(
            transito.index("_perder_vivienda()"),
            transito.index("super._al_pisar_salida(cuerpo, salida)"),
        )

    def test_la_oficina_nocturna_reutiliza_la_planta_y_solo_deja_dormir(self):
        self.assertIn('EspaciosCatalogo.de_fase("archivo").duplicate(true)', self.capa)
        self.assertIn('refugio["figuras"] = []', self.capa)
        self.assertIn('"destino": "sueño"', self.capa)
        self.assertIn('"rotulo": "SALIDA_DORMIR"', self.capa)

    def test_la_reasignacion_devuelve_casa_pero_no_resucita_al_gato(self):
        for clave in ("ultimo_resuelto", "ultimo_estado", "pagados", "impagos"):
            self.assertIn(f'"{clave}"', self.jornada)
        self.assertIn('nueva_vida["gato"] = gato', self.jornada)

    def test_este_corte_no_decide_el_sueno_degradado(self):
        self.assertNotIn("Sueno.noche(", self.capa)
        self.assertNotIn("sueno_escenas", self.capa)


if __name__ == "__main__":
    unittest.main()
