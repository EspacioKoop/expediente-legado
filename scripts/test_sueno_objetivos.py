from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
REGLA = ROOT / "godot" / "guion" / "sueno_objetivos.gd"
GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
TRABAJILLOS = ROOT / "godot" / "guion" / "dia_trabajillos_app.gd"
ONBOARDING = ROOT / "godot" / "guion" / "dia_onboarding_app.gd"
CLIMA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
REACTIVO = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"


class SuenoObjetivosTest(unittest.TestCase):
    def setUp(self):
        self.regla = REGLA.read_text(encoding="utf-8")
        self.gato = GATO.read_text(encoding="utf-8")
        self.trabajillos = TRABAJILLOS.read_text(encoding="utf-8")
        self.onboarding = ONBOARDING.read_text(encoding="utf-8")
        self.clima = CLIMA.read_text(encoding="utf-8")
        self.escena = ESCENA.read_text(encoding="utf-8")
        self.reactivo = REACTIVO.read_text(encoding="utf-8")

    def test_vertical_tres_objetivos_dos_requeridos(self):
        self.assertIn("POSIBLES_PRIMER_CORTE := 3", self.regla)
        self.assertIn("REQUERIDOS_PRIMER_CORTE := 2", self.regla)
        self.assertIn('"completados": []', self.regla)
        self.assertIn('completados.has(id)', self.regla)
        self.assertIn('estado["resuelto"] = true', self.regla)

    def test_puzzle_puede_ocupar_una_plaza_sin_cambiar_el_umbral(self):
        self.assertIn("static func sustituir_puntuable(", self.regla)
        self.assertIn('nuevo["cuenta"] = true', self.regla)
        self.assertIn('reemplazo["cuenta"] = false', self.regla)
        self.assertIn("registrar_objetivo_puzzle_onirico", self.gato)
        self.assertIn('"tipo": "pista_onirica"', self.gato)
        self.assertIn("_retirar_objetivo_espacial", self.gato)
        self.assertIn("not _objetivo_puntuable(estado, objetivo_id)", self.gato)
        self.assertIn("PuzzleOnirico.ESTADO_COMPLETADO", self.gato)
        self.assertIn("SuenoObjetivos.completar(estado, objetivo_id)", self.gato)
        self.assertIn("SuenoObjetivos.fallar(estado, objetivo_id)", self.gato)

    def test_una_anomalia_de_folio_leido_hoy_ocupa_una_plaza(self):
        # El primer vertical pedía un objetivo derivado de contenido leído ese
        # día. La fuente legítima ya existe (#87): las deformaciones que
        # `SuenoUtileria` marca con `documento_origen`.
        self.assertIn("registrar_objetivo_anomalia_documental", self.gato)
        self.assertIn("_id_objetivo_anomalia_documental", self.gato)
        self.assertIn('"tipo": "anomalia"', self.gato)
        self.assertIn('"condicion": "observar"', self.gato)
        self.assertIn("registrar_objetivo_anomalia_documental", self.reactivo)
        self.assertIn('get_meta("documento_origen"', self.reactivo)

    def test_observar_la_anomalia_es_la_condicion_de_su_plaza(self):
        self.assertIn("completar_objetivo_anomalia_documental", self.reactivo)
        self.assertIn("SuenoObjetivos.completar(estado, objetivo_id)", self.gato)
        # El progreso viaja en el mismo guardado que el catálogo: la llamada
        # ocurre antes del guardado condicional, no después.
        completar = self.reactivo.index("completar_objetivo_anomalia_documental(anomalia_id")
        guardado = self.reactivo.index('dia._guardar_o_avisar("")')
        self.assertLess(completar, guardado)

    def test_la_plaza_documental_no_monta_una_zona_pisable(self):
        # Observar y pisar serían dos condiciones para el mismo objetivo.
        self.assertIn('objetivo.get("solo_guia", false)', self.gato)
        self.assertIn('"solo_guia": true', self.gato)

    def test_contrato_real_se_ejecuta_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/sueno_objetivos_smoke.gd",
            "Sueño objetivos smoke: OK",
        )

    def test_el_sueno_ya_no_monta_la_salida_como_progreso_normal(self):
        self.assertIn('espacio["salidas"] = []', self.gato)
        self.assertIn("_montar_objetivos_sueno", self.gato)
        self.assertIn('zona.set_meta("objetivo"', self.gato)
        self.assertIn("_al_pisar_objetivo", self.gato)

    def test_segundo_objetivo_resuelve_y_transiciona(self):
        self.assertIn("SuenoObjetivos.resuelto(estado)", self.gato)
        self.assertIn('jornada["sueno_escenas"].pop_front()', self.gato)
        self.assertIn("Jornada.despertar(jornada)", self.gato)
        self.assertIn('_entrar_en(destino)', self.gato)

    def test_resolucion_tiene_cerrojo_contra_doble_transicion(self):
        self.assertIn("var _resolviendo_objetivos := false", self.gato)
        self.assertIn("if _resolviendo_objetivos:", self.gato)
        self.assertIn("_resolviendo_objetivos = true", self.gato)
        # La escena siguiente reinicia el cerrojo al entrar, no desde un timer
        # externo que pudiera dejarlo arrastrado entre escenas.
        self.assertIn("func _entrar_en(fase: String) -> void:", self.gato)
        self.assertIn("_resolviendo_objetivos = false\n\tsuper._entrar_en(fase)", self.gato)

    def test_fallo_de_guardado_no_consume_otra_escena_al_reintentar(self):
        self.assertIn("var jornada_antes := jornada.duplicate(true)", self.gato)
        self.assertIn("if not _guardar_o_avisar(destino):", self.gato)
        self.assertIn("jornada.clear()", self.gato)
        self.assertIn("jornada.merge(jornada_antes, true)", self.gato)
        self.assertIn("_resolviendo_objetivos = false", self.gato)

    def test_feedback_de_despertar_solo_aparece_despues_de_guardar(self):
        self.assertIn("var dia_nuevo := -1", self.gato)
        self.assertIn("if dia_nuevo >= 0:", self.gato)
        guardar = self.gato.index("if not _guardar_o_avisar(destino):")
        feedback = self.gato.index("if dia_nuevo >= 0:")
        self.assertGreater(feedback, guardar)

    def test_el_gato_apunta_a_objetivo_y_no_a_puerta(self):
        self.assertIn('extends "res://guion/dia_trabajillos_app.gd"', self.gato)
        self.assertIn('extends "res://guion/dia_alquiler_app.gd"', self.trabajillos)
        self.assertIn('espacio.get("salidas", [])', self.gato)
        self.assertIn('_salida_guia = _objetivos_espacio[0].get("pos", _entrada_guia)', self.gato)
        self.assertIn("_hay_rumbo_guia = true", self.gato)

    def test_la_escena_conserva_la_capa_raiz_del_gato(self):
        self.assertIn('path="res://guion/dia_clima_app.gd"', self.escena)
        self.assertIn('extends "res://guion/dia_calle_app.gd"', self.clima)
        calle = (ROOT / "godot/guion/dia_calle_app.gd").read_text(encoding="utf-8")
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', calle)
        self.assertIn('extends "res://guion/dia_gato_app.gd"', self.onboarding)


if __name__ == "__main__":
    unittest.main()
