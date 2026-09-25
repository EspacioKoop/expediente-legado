from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "godot" / "guion" / "huellas_ambientales.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_huellas_ambientales_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
PARTIDA = ROOT / "godot" / "guion" / "partida.gd"
CLIMA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
DRESSING = ROOT / "godot" / "guion" / "dia_dressing_cc0_app.gd"
GODOT_TEST = ROOT / "godot" / "pruebas" / "pruebas_huellas_ambientales_959.gd"
VERIFIER = ROOT / "scripts" / "verificar_godot.py"
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
LAMPARA = ROOT / "godot" / "guion" / "lampara_interactiva_3d.gd"
TELEVISOR = ROOT / "godot" / "guion" / "television_interactiva_3d.gd"


class HuellasAmbientales959Test(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding="utf-8")
        self.controller = CONTROLLER.read_text(encoding="utf-8")
        self.dia = DIA.read_text(encoding="utf-8")
        self.partida = PARTIDA.read_text(encoding="utf-8")
        self.clima = CLIMA.read_text(encoding="utf-8")
        self.dressing = DRESSING.read_text(encoding="utf-8")
        self.godot_test = GODOT_TEST.read_text(encoding="utf-8")
        self.verifier = VERIFIER.read_text(encoding="utf-8")
        self.visor = VISOR.read_text(encoding="utf-8")
        self.lampara = LAMPARA.read_text(encoding="utf-8")
        self.televisor = TELEVISOR.read_text(encoding="utf-8")

    def test_estado_es_partida_y_no_archivo_paralelo(self):
        self.assertIn('"huellas_ambientales": {}', self.partida)
        self.assertIn("HuellasAmbientales.validar", self.partida)
        self.assertIn("class_name HuellasAmbientales", self.core)
        self.assertNotIn("FileAccess", self.core)

    def test_interacciones_reales_optan_con_ids_estables(self):
        self.assertIn('"archivo:terminal_siga"', self.clima)
        self.assertIn('"archivo:archivador_%d"', self.clima)
        self.assertIn('"dressing:%s"', self.dressing)
        self.assertIn('set_meta("huella_ambiental_tipo"', self.clima)

    def test_presentacion_es_diegetica_y_barata(self):
        self.assertIn("PlaneMesh.new()", self.controller)
        self.assertIn("SHADOW_CASTING_SETTING_OFF", self.controller)
        self.assertIn("TRANSPARENCY_ALPHA", self.controller)
        self.assertNotIn("CanvasLayer", self.controller)
        self.assertNotIn("Label", self.controller)
        self.assertNotIn("Input.", self.controller)

    def test_lecturas_de_documentos_dejan_desgaste_persistente(self):
        self.assertRegex(self.visor, r"HuellasAmbientales\s*\.\s*registrar")
        self.assertIn('"archivo:documento:%s:%s"', self.visor)
        self.assertIn('"lectura"', self.visor)
        self.assertIn("HuellasAmbientales.intensidad_de", self.visor)
        self.assertIn("_color_papel_documento(registro)", self.visor)
        self.assertIn("if not ya_visto or huella_mutada or auditoria_mutada:", self.visor)

    def test_transito_repetido_tiene_umbral_y_celda_estable(self):
        self.assertIn('PREFIJO_TRANSITO := "transito:"', self.controller)
        self.assertIn("PASADAS_PARA_MARCA := 3", self.controller)
        self.assertIn("CELDA_TRANSITO := 1.25", self.controller)
        self.assertIn("_sembrar_celda_actual(dia)", self.controller)
        self.assertIn("HuellasAmbientales.registrar(dia.partida.estado, id, \"paso\", fase)", self.controller)
        self.assertIn("_montar_transito_guardado(dia, mundo)", self.controller)
        self.assertIn('"transito:archivo:0:0"', self.godot_test)
        self.assertIn("tres retornos reales crean desgaste de tránsito", self.godot_test)
        self.assertIn("reconstruir el mundo no suma una pasada fantasma", self.godot_test)

    def test_equipos_domesticos_dejan_huella_sin_estado_paralelo(self):
        self.assertIn('"equipo"', self.core)
        self.assertIn('"equipo":', self.controller)
        self.assertIn('set_meta("huella_ambiental_id", "casa:lampara_pie")', self.lampara)
        self.assertIn('set_meta("huella_ambiental_tipo", "equipo")', self.lampara)
        self.assertIn('set_meta("huella_ambiental_id", "casa:televisor")', self.televisor)
        self.assertIn('set_meta("huella_ambiental_tipo", "equipo")', self.televisor)
        self.assertNotIn("HuellasAmbientales.registrar", self.lampara)
        self.assertNotIn("HuellasAmbientales.registrar", self.televisor)

    def test_no_convierte_huellas_en_progreso(self):
        for forbidden in ("Sellos.", "Prometeo.", "Economia.", "Acusacion."):
            self.assertNotIn(forbidden, self.controller)
            self.assertNotIn(forbidden, self.core)

    def test_controller_esta_montado_y_tiene_gate_runtime(self):
        self.assertIn("dia_huellas_ambientales_app.gd", self.dia)
        self.assertIn("HuellasAmbientalesController", self.dia)
        self.assertIn('"huellas-ambientales"', self.verifier)
        self.assertIn("pruebas_huellas_ambientales_959.gd", self.verifier)
        self.assertIn("la recarga conserva intensidad acumulada", self.godot_test)


if __name__ == "__main__":
    unittest.main()
