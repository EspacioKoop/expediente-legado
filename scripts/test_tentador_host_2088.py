from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"
HOST = (GUION / "juicio_combate_tentador_host_3d.gd").read_text(encoding="utf-8")
RUNTIME = (GUION / "juicio_combate_tentador_runtime_2088.gd").read_text(encoding="utf-8")
PRESENTACION = (GUION / "juicio_combate_tentador_3d.gd").read_text(encoding="utf-8")
HOST_COMPACTO = re.sub(r"\s+", "", HOST)


class TentadorHost2088Test(unittest.TestCase):
    def test_montaje_reutiliza_runtime_y_presentacion(self):
        self.assertIn('const VARIANTE := "tentador_miniado"', HOST)
        self.assertIn("RUNTIME.nuevo(raiz)", HOST)
        self.assertIn("RUNTIME.avanzar(runtime, 0.0,", HOST)
        self.assertIn("PRESENTACION.montar(rival)", HOST)
        self.assertIn('anfitrion.set("_figura_rival", figura)', HOST)
        self.assertNotIn("JuicioCombateArquetipos.nuevo(", HOST)

    def test_tick_delega_en_mimetico_y_no_duplica_timers(self):
        self.assertIn("RUNTIME.avanzar(runtime, delta, patron_observado)", HOST)
        self.assertIn("PRESENTACION.pintar(", HOST_COMPACTO)
        for duplicado in (
            "MIMETICO_TELEGRAFO",
            "MIMETICO_REPETICION",
            "MIMETICO_RECUPERACION",
            'unidad["temporizador"]',
        ):
            with self.subTest(duplicado=duplicado):
                self.assertNotIn(duplicado, HOST)

    def test_observacion_actual_es_patron_corto_del_jugador(self):
        self.assertIn('const PATRON_CORTO := "ataque_corto"', HOST)
        self.assertIn('anfitrion.get("_recarga_jugador")', HOST)
        helper = HOST.split("static func _patron_observado(", 1)[1].split(
            "static func _resultado_patron(", 1
        )[0]
        self.assertIn("PATRON_CORTO", helper)
        self.assertNotIn("ReligionEventos", helper)
        self.assertNotIn("CombateContextual", helper)

    def test_repeticion_resuelve_un_solo_impacto_por_entrada(self):
        self.assertIn('"_repeticion_emitida": false', HOST)
        self.assertIn('estado["_repeticion_emitida"] = true', HOST)
        self.assertIn("fase_anterior != ARQUETIPOS.REPETIR", HOST)
        self.assertIn('anfitrion.call("_aplicar_impacto_rival"', HOST_COMPACTO)
        self.assertIn("REGLAS.resultado_ataque_rival(", HOST_COMPACTO)
        self.assertNotIn("_determinacion_jugador", HOST)
        self.assertNotIn("_terminar(", HOST)

    def test_patrones_se_traducen_a_geometria_comun_sin_dano_propietario(self):
        for patron in ("ataque_corto", "linea", "carga_lineal", "zona"):
            with self.subTest(patron=patron):
                self.assertIn(f'"{patron}"', HOST)
        self.assertIn("ARQUETIPO_HOST.impacto_linea(", HOST_COMPACTO)
        self.assertIn("REGLAS.ALCANCE_RIVAL", HOST)
        self.assertIn("RADIO_ZONA", HOST)
        for prohibido in ("dano", "Partida.", "Jornada.", "loot", "XP"):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, HOST)

    def test_recuperacion_expone_ventana_y_reduccion_solo_va_a_presentacion(self):
        self.assertIn('salida.get("ventana_respuesta", false)', HOST)
        self.assertIn('anfitrion.get("reduccion_movimiento")', HOST)
        self.assertIn('JuicioCombateEscenografia3D.gesto(figura, "encajar")', HOST)
        self.assertNotIn("reduccion_movimiento", RUNTIME)
        self.assertIn("reduccion_movimiento", PRESENTACION)


if __name__ == "__main__":
    unittest.main()
