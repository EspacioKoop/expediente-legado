import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "godot" / "guion" / "sueno_hidra.gd"
INTERACTION = ROOT / "godot" / "guion" / "sueno_hidra_interaccion_3d.gd"
VIGILIA = ROOT / "godot" / "guion" / "dia_hidra_vigilia_app.gd"
NIGHT = ROOT / "godot" / "guion" / "dia_hidra_sueno_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
SMOKE = ROOT / "godot" / "pruebas" / "pruebas_hidra_noche.gd"


class HidraNocheRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding="utf-8")
        cls.interaction = INTERACTION.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.night = NIGHT.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_capa_jugable_reutiliza_el_vertical(self):
        self.assertIn("var _hidra: SuenoHidra", self.interaction)
        self.assertIn("_hidra.accion_sintoma()", self.interaction)
        self.assertIn("_hidra.observar_conexiones()", self.interaction)
        self.assertIn("_hidra.accion_nodo_comun()", self.interaction)
        self.assertNotIn("Input.", self.interaction)
        self.assertIn("const MAX_CABEZAS := 9", self.core)
        self.assertIn("const MAX_REGENERACIONES := 2", self.core)
        self.assertIn("return semillas.has(SEMILLA)", self.core)

    def test_tres_intenciones_son_interactuables_reales(self):
        self.assertIn('"SintomaHidra"', self.interaction)
        self.assertIn('"ConexionesHidra"', self.interaction)
        self.assertIn('"NodoComunHidra"', self.interaction)
        self.assertIn("Interactuable3D.new()", self.interaction)
        self.assertIn("CollisionShape3D.new()", self.interaction)
        self.assertIn("nodo_legible", self.interaction)
        self.assertIn("_nodo.habilitado = _habilitada and nodo_legible and not terminada", self.interaction)

    def test_vigilia_solo_monta_hydra_loop_en_casa(self):
        self.assertIn('fase", "")) != "casa"', self.vigilia)
        self.assertIn("var cartucho := HidraVigilia.new()", self.vigilia)
        self.assertIn("cartucho.configurar(jornada)", self.vigilia)
        self.assertNotIn("activar_semilla_onirica", self.vigilia)

    def test_noche_consume_selector_y_asignacion_comunes(self):
        self.assertRegex(
            self.night,
            r"SemillasOniricas\s*\.\s*seleccionar_para_noche\s*\(",
        )
        self.assertIn("MitologiasNoche.MAX_FAMILIAS_NOCHE", self.night)
        self.assertRegex(
            self.night,
            r"MitologiasNoche\s*\.\s*corresponde_a_escena\s*\(",
        )
        self.assertIn("SuenoHidraInteraccion3D.ID_MITO", self.night)
        self.assertIn("SemillasOniricas.obtener_semillas(dia.jornada)", self.night)
        self.assertNotIn("activar_semilla_onirica", self.night)

    def test_noche_conserva_sala_y_reduccion_movimiento(self):
        self.assertIn('fase != "sueño"', self.night)
        self.assertIn("var hidra := SuenoHidraInteraccion3D.new()", self.night)
        self.assertIn("_ancla_entre_entrada_y_salida", self.night)
        self.assertIn("PreferenciasSiga.cargar()", self.night)
        self.assertIn("mundo.add_child(hidra)", self.night)
        self.assertNotIn("mundo.queue_free", self.night)

    def test_dia_monta_ambos_controladores(self):
        self.assertIn('path="res://guion/dia_hidra_vigilia_app.gd"', self.dia)
        self.assertIn('path="res://guion/dia_hidra_sueno_app.gd"', self.dia)
        self.assertIn('[node name="HidraVigiliaController" type="Node" parent="."]', self.dia)
        self.assertIn('[node name="HidraSuenoController" type="Node" parent="."]', self.dia)

    def test_ruta_hidra_no_usa_constructor_bool(self):
        for codigo in (self.core, self.interaction, self.night, self.smoke):
            self.assertNotIn("bool(", codigo)

    def test_smoke_cubre_proliferacion_regeneracion_y_raiz(self):
        self.assertIn("not nodo.interactuar(actor)", self.smoke)
        self.assertIn("int(estado.get(\"regeneraciones\", 0)) == 1", self.smoke)
        self.assertIn('estado.get("nodo_legible", false) == true', self.smoke)
        self.assertIn("encuentro.resuelta()", self.smoke)
        self.assertIn('hidra.modo_aparicion() == "fundido_discreto"', self.smoke)

    def test_lectura_visual_conecta_raiz_y_colapsa_a_semilla(self):
        self.assertIn('"ConexionesRaiz"', self.core)
        self.assertIn("cable.look_at(fin, Vector3.UP)", self.core)
        self.assertIn('"SemillaHydraLoopFinal"', self.core)
        self.assertIn('get_node_or_null("ConexionesRaiz")', self.smoke)
        self.assertIn('get_node_or_null("ResolucionHidra/SemillaHydraLoopFinal")', self.smoke)

    @unittest.skipUnless(
        shutil.which(os.environ.get("GODOT_BIN", "godot4")),
        "Godot no está disponible en PATH",
    )
    def test_smoke_godot_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="hidra-noche-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    "res://pruebas/pruebas_hidra_noche.gd",
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=120,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")


if __name__ == "__main__":
    unittest.main()
