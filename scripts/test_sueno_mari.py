import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_mari.gd"
VIGILIA = ROOT / "godot" / "guion" / "mari_vigilia.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_mari.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "mari_vigilia.tscn"
REFERENCIAS = ROOT / "docs" / "assets" / "mari-referencias.md"
CONTROLLER = ROOT / "godot" / "guion" / "dia_mari_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "res://pruebas/pruebas_mari.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoMariTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.escena_sueno = ESCENA_SUENO.read_text(encoding="utf-8")
        cls.escena_vigilia = ESCENA_VIGILIA.read_text(encoding="utf-8")
        cls.referencias = REFERENCIAS.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_semilla_usa_catalogo_comun(self):
        self.assertIn('"mari",', self.semillas)
        self.assertIn('ID_MITO := "mari"', self.sueno)
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_mari"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertRegex(
            self.sueno,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )

    def test_vigilia_es_deliberada_y_sin_hud(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("INSPECCIONES_MINIMAS := 2", self.vigilia)
        self.assertIn("_desplegado = true", self.vigilia)
        self.assertIn("_ruta_trazada = true", self.vigilia)
        self.assertRegex(
            self.vigilia,
            r"SuenoMari\s*\.\s*registrar_semilla\s*\(",
        )
        combinado = self.sueno + self.vigilia
        self.assertNotIn("Label.new()", combinado)
        self.assertNotIn("CanvasLayer", combinado)

    def test_clima_transforma_navegacion_sin_azar(self):
        self.assertIn('"abrir_compuerta": CLIMA_LLUVIA', self.sueno)
        self.assertIn('"abrir_conducto": CLIMA_VIENTO', self.sueno)
        self.assertIn('"cerrar_conducto": CLIMA_NIEBLA', self.sueno)
        self.assertIn('"refugiarse": CLIMA_TORMENTA', self.sueno)
        self.assertIn("const RUTAS_POR_CLIMA :=", self.sueno)
        self.assertIn("RUTA_CAUCE", self.sueno)
        self.assertIn("RUTA_CORNISA", self.sueno)
        self.assertIn("RUTA_CUEVA", self.sueno)
        self.assertNotIn("RandomNumberGenerator", self.sueno)
        self.assertNotIn("randf", self.sueno)
        self.assertNotIn("randi", self.sueno)

    def test_cueva_paisaje_y_orientacion(self):
        self.assertIn('cueva.name = "VolumenCueva"', self.sueno)
        self.assertIn('cotidiano.name = "ArquitecturaCotidiana"', self.sueno)
        self.assertIn('"Archivador%d"', self.sueno)
        self.assertIn('"PresenciaPaisaje"', self.sueno)
        self.assertIn('"BalizaCercana"', self.sueno)
        self.assertIn('"lejana": _clima != CLIMA_NIEBLA', self.sueno)
        self.assertIn('"cercana": true', self.sueno)
        self.assertNotIn("CharacterBody3D.new()", self.sueno)

    def test_reduccion_movimiento_conserva_mecanica(self):
        self.assertIn('"corte_fundido" if reduccion_movimiento', self.sueno)
        self.assertIn('"duracion": 0.0 if reduccion_movimiento', self.sueno)
        self.assertIn('"particulas": false if reduccion_movimiento', self.sueno)
        self.assertIn('"mover_camara": false', self.sueno)
        self.assertIn('"flash": false', self.sueno)
        self.assertIn('RUTA_RETORNO: true', self.sueno)

    def test_recorrido_real_reutiliza_vigilia_y_selector_comunes(self):
        self.assertIn('String(dia._vivienda()) != "casa"', self.controller)
        self.assertIn("MariVigilia.new()", self.controller)
        self.assertIn("folleto.configurar(jornada)", self.controller)
        self.assertIn("SemillasOniricas", self.controller)
        self.assertIn(". seleccionar_para_noche(", self.controller)
        self.assertIn("MitologiasNoche", self.controller)
        self.assertIn(". corresponde_a_escena(", self.controller)
        self.assertIn("SuenoMari.ID_MITO", self.controller)
        self.assertIn("PreferenciasSiga.cargar()", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)
        self.assertIn('path="res://guion/dia_mari_app.gd"', self.dia)
        self.assertIn('[node name="MariController" type="Node" parent="."]', self.dia)

    def test_clima_tiene_controles_interactuables_reales(self):
        self.assertIn("Interactuable3D.new()", self.sueno)
        self.assertIn('controles.name = "ControlesClimaticos"', self.sueno)
        self.assertIn('"CompuertaLluvia"', self.sueno)
        self.assertIn('"ConductoViento"', self.sueno)
        self.assertIn('"ConductoNiebla"', self.sueno)
        self.assertIn('"RefugioTormenta"', self.sueno)
        self.assertIn("control.activado.connect", self.sueno)
        self.assertIn("aplicar_accion(accion, reduccion_movimiento)", self.sueno)

    def test_fuentes_culturales_preceden_arte_final(self):
        self.assertIn("José Miguel de Barandiarán", self.referencias)
        self.assertIn("Euskariana", self.referencias)
        self.assertIn("Gobierno Vasco", self.referencias)
        self.assertIn("Auñamendi Eusko Entziklopedia", self.referencias)
        self.assertIn("invención jugable de SIGA-98", self.referencias)
        self.assertIn("no se mezclan automáticamente relatos", self.referencias)
        self.assertIn("procedencia.json", self.referencias)

    def test_escenas_standalone_apuntan_a_verticales(self):
        self.assertIn('path="res://guion/sueno_mari.gd"', self.escena_sueno)
        self.assertIn('[node name="SuenoMari" type="Node3D"]', self.escena_sueno)
        self.assertIn('path="res://guion/mari_vigilia.gd"', self.escena_vigilia)
        self.assertIn('[node name="MariVigilia" type="Area3D"]', self.escena_vigilia)

    def test_contrato_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 55, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
