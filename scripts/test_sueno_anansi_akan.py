from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SUENO = ROOT / "godot" / "guion" / "sueno_anansi_akan.gd"
VIGILIA = ROOT / "godot" / "guion" / "anansi_akan_vigilia.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_anansi_akan_app.gd"
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_anansi_akan.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "anansi_akan_vigilia.tscn"
FUENTES = ROOT / "docs" / "assets" / "anansi-akan-fuentes.md"
PRUEBA_GODOT = ROOT / "godot" / "pruebas" / "pruebas_anansi_akan.gd"


class SuenoAnansiAkanTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.escena_sueno = ESCENA_SUENO.read_text(encoding="utf-8")
        cls.escena_vigilia = ESCENA_VIGILIA.read_text(encoding="utf-8")
        cls.fuentes = FUENTES.read_text(encoding="utf-8")
        cls.prueba_godot = PRUEBA_GODOT.read_text(encoding="utf-8")

    def test_semilla_catalogada_y_gateada_por_escucha_completa(self):
        self.assertIn('"anansi_akan",', self.semillas)
        self.assertIn('const ID_MITO := "anansi_akan"', self.sueno)
        self.assertIn('const FUENTE_VIGILIA := "cassette:anansi_akan_relato_98"', self.sueno)
        self.assertIn("const PASOS_RELATO_MINIMOS := 3", self.sueno)
        self.assertIn("if pasos_escuchados < PASOS_RELATO_MINIMOS or not relato_terminado:", self.sueno)
        self.assertIn("SemillasOniricas.activar_semilla_onirica(", self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado).has(ID_MITO)", self.sueno)

    def test_cassette_es_deliberado_y_no_activa_por_presencia(self):
        self.assertIn("class_name AnansiAkanVigilia", self.vigilia)
        self.assertIn("const PASOS_MINIMOS := 3", self.vigilia)
        self.assertIn("_pasos_escuchados = mini(_pasos_escuchados + 1, PASOS_MINIMOS)", self.vigilia)
        self.assertIn("_terminada = _pasos_escuchados >= PASOS_MINIMOS", self.vigilia)
        self.assertIn("SuenoAnansiAkan.registrar_semilla(", self.vigilia)
        self.assertNotIn("_activada = true", self.vigilia)

    def test_red_limita_nodos_y_relaciones_y_produce_efecto_remoto(self):
        for nodo in ["telefono", "impresora", "archivador", "puerta"]:
            self.assertIn(f'"{nodo}": {{"pos":', self.sueno)
        for hilo in [
            "telefono_impresora",
            "impresora_archivador",
            "archivador_puerta",
            "telefono_puerta_senuelo",
        ]:
            self.assertIn(f'"{hilo}": {{', self.sueno)
        self.assertIn('resultado["efecto_remoto"] = efecto_remoto', self.sueno)
        self.assertIn("_aplicar_delta_nodo(nodos, destino_id", self.sueno)
        self.assertNotIn("for i in 100", self.sueno)

    def test_senuelo_es_observable_sin_ensayo_ciego(self):
        self.assertIn('"real": false', self.sueno)
        self.assertIn('"pista": "orientacion_incompatible_en_destino"', self.sueno)
        self.assertIn('"senuelo_detectable": pista == "orientacion_incompatible_en_destino"', self.sueno)
        self.assertIn('"PistaOrientacion"', self.sueno)
        self.assertIn('hilo.set_meta("anansi_pista"', self.sueno)

    def test_errores_son_reversibles_y_cortes_reconectables(self):
        self.assertIn('conexion["reconectable"] = true', self.sueno)
        self.assertIn('"cortar":', self.sueno)
        self.assertIn('conexion["activa"] = false', self.sueno)
        self.assertIn('"reconectar":', self.sueno)
        self.assertIn("static func revertir_ultima(", self.sueno)
        self.assertIn('resultado["reversible"] = true', self.sueno)
        self.assertIn('resultado["revertido"] = true', self.sueno)

    def test_reduccion_movimiento_no_cambia_la_logica(self):
        presentar = self.sueno.split("static func plan_presentacion(", 1)[1].split(
            "static func _aplicar_delta_nodo(", 1
        )[0]
        self.assertIn('"duracion": 0.0 if movimiento_reducido else 0.22', presentar)
        self.assertIn('"sacudida_camara": false', presentar)
        self.assertIn('"pistas_visuales": true', presentar)

        manipular = self.sueno.split("static func manipular_conexion(", 1)[1].split(
            "static func revertir_ultima(", 1
        )[0]
        self.assertNotIn("reduccion_movimiento", manipular)
        self.assertNotIn("movimiento_reducido", manipular)

    def test_wiring_reutiliza_selector_y_asignacion_comunes(self):
        self.assertIn('fase == "casa"', self.controller)
        self.assertIn("AnansiAkanVigilia.new()", self.controller)
        self.assertIn("cassette.configurar(jornada)", self.controller)
        self.assertIn('fase != "sueño"', self.controller)
        self.assertIn("SemillasOniricas.seleccionar_para_noche(", self.controller)
        self.assertIn("MitologiasNoche.corresponde_a_escena(", self.controller)
        self.assertIn("SuenoAnansiAkan.ID_MITO", self.controller)
        self.assertIn("PreferenciasSiga.cargar()", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)

    def test_controller_esta_montado_en_dia_real(self):
        self.assertIn('path="res://guion/dia_anansi_akan_app.gd"', self.dia)
        self.assertIn('[node name="AnansiAkanController" type="Node" parent="."]', self.dia)

    def test_escenas_standalone_apuntan_a_los_scripts(self):
        self.assertIn('path="res://guion/sueno_anansi_akan.gd"', self.escena_sueno)
        self.assertIn('[node name="SuenoAnansiAkan" type="Node3D"]', self.escena_sueno)
        self.assertIn('path="res://guion/anansi_akan_vigilia.gd"', self.escena_vigilia)
        self.assertIn('[node name="AnansiAkanVigilia" type="Area3D"]', self.escena_vigilia)

    def test_fuentes_delimitan_raiz_akan_y_transformacion_jamaicana(self):
        texto = self.fuentes.lower()
        self.assertIn("anansi finds a fool", texto)
        self.assertIn("akan-ashanti folk-tales", texto)
        self.assertIn("anansi's journey", texto)
        self.assertIn("jamaica", texto)
        self.assertIn("red de causalidad", texto)
        self.assertIn("no se documentan como iconografía tradicional akan", texto)
        self.assertIn("diseño original de siga-98", texto)
        self.assertNotIn("dios araña genérico", self.sueno.lower())

    def test_runtime_cubre_aceptacion_principal(self):
        for evidencia in [
            "la red parte de cuatro nodos",
            "el señuelo se detecta por observación",
            "tensar afecta un nodo remoto rastreable",
            "se puede deshacer la última manipulación",
            "una conexión cortada siempre puede reconectarse",
            "movimiento reducido conserva señales visuales",
        ]:
            self.assertIn(evidencia, self.prueba_godot)


if __name__ == "__main__":
    unittest.main()
