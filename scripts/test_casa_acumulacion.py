import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
ACUMULACION = ROOT / "godot" / "guion" / "casa_acumulacion_3d.gd"
CONSECUENCIAS = ROOT / "godot" / "guion" / "casa_consecuencias_3d.gd"
HUELLA_VIDA = ROOT / "godot" / "guion" / "casa_huella_vida_3d.gd"
AMBIENTAL = ROOT / "godot" / "guion" / "casa_estado_ambiental.gd"
LAMPARA = ROOT / "godot" / "guion" / "lampara_interactiva_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_acumulacion_casa_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "pruebas/pruebas_casa_acumulacion.gd"
PRUEBA_CONSECUENCIAS = "pruebas/pruebas_casa_consecuencias.gd"
PRUEBA_HUELLA_VIDA = "pruebas/pruebas_casa_huella_vida.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CasaAcumulacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.acumulacion = ACUMULACION.read_text(encoding="utf-8")
        cls.consecuencias = CONSECUENCIAS.read_text(encoding="utf-8")
        cls.huella_vida = HUELLA_VIDA.read_text(encoding="utf-8")
        cls.ambiental = AMBIENTAL.read_text(encoding="utf-8")
        cls.lampara = LAMPARA.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_renderer_es_acotado_y_sin_estado_paralelo(self):
        self.assertIn("const MAX_OBJETOS := 8", self.acumulacion)
        self.assertIn('estado_ambiental.get("objetos_casa", [])', self.acumulacion)
        self.assertIn('estanteria.get_node_or_null(NOMBRE_RAIZ)', self.acumulacion)
        self.assertIn('nodo.set_meta("objeto_id"', self.acumulacion)
        self.assertIn('nodo.set_meta("origen"', self.acumulacion)
        self.assertIn('salida.sort_custom(', self.acumulacion)
        self.assertNotIn("porcentaje", self.acumulacion.lower())
        self.assertNotIn("puntuacion", self.acumulacion.lower())
        self.assertNotIn("bonificacion", self.acumulacion.lower())

    def test_reutiliza_material_psx_y_no_assets_externos(self):
        self.assertIn("Modelos._pintar(malla, color)", self.acumulacion)
        self.assertIn("BoxMesh.new()", self.acumulacion)
        self.assertIn("CylinderMesh.new()", self.acumulacion)
        for extension in (".glb", ".png", ".jpg", ".webp"):
            self.assertNotIn(extension, self.acumulacion.lower())

    def test_iman_postal_usa_nevera_y_conserva_fallback(self):
        self.assertIn('const ID_IMAN_CALENDARIO := "postal_iman_calendario"', self.acumulacion)
        self.assertIn('raiz.find_child("NeveraCasa", true, false)', self.acumulacion)
        self.assertIn("_montar_iman_calendario(nevera, objeto)", self.acumulacion)
        self.assertIn('iman.set_meta("objeto_id"', self.acumulacion)
        self.assertIn('iman.set_meta("origen"', self.acumulacion)
        self.assertIn('iman.set_meta("variante", "iman_calendario")', self.acumulacion)
        self.assertIn("if _es_iman_calendario(objeto) and nevera != null", self.acumulacion)
        self.assertNotIn("Inventario.guardar_en_casa", self.acumulacion)

    def test_consecuencias_derivan_de_hechos_y_no_de_medidores(self):
        self.assertIn('"consecuencias_casa": _consecuencias_domesticas(jornada)', self.ambiental)
        self.assertIn('consecuencia.begins_with("casa_")', self.ambiental)
        self.assertIn('estado_ambiental.get("consecuencias_casa", [])', self.consecuencias)
        self.assertIn('const NOMBRE_RAIZ := "ConsecuenciasCasa"', self.consecuencias)
        for nombre in (
            "BombillaFundida",
            "GrifoGoteando",
            "PersianaAtascada",
            "CalentadorAveriado",
            "ElectrodomesticoRoto",
        ):
            self.assertIn(f'marca.name = "{nombre}"', self.consecuencias)
        self.assertIn('"ReciboPendiente", Vector3(', self.consecuencias)
        self.assertIn('"MultaPendiente", Vector3(', self.consecuencias)
        self.assertIn("marca.name = nombre", self.consecuencias)
        self.assertNotIn("Label.new()", self.consecuencias)
        self.assertNotIn("porcentaje", self.consecuencias.lower())
        self.assertNotIn("nivel_pobreza", self.consecuencias.lower())

    def test_huella_vida_deriva_de_hechos_reales(self):
        self.assertIn('"comida_estado": _estado_comida(jornada)', self.ambiental)
        self.assertIn('"alquiler_estado": _estado_alquiler(jornada)', self.ambiental)
        self.assertIn('estado_ambiental.get("vuelta", 1)', self.huella_vida)
        self.assertIn('"DespensaConComida"', self.huella_vida)
        self.assertIn('"DespensaEscasa"', self.huella_vida)
        self.assertIn('"ReciboAlquilerPagado"', self.huella_vida)
        self.assertIn('"AvisoAlquilerImpagado"', self.huella_vida)
        self.assertIn('"VueltasCasa"', self.huella_vida)
        self.assertNotIn("Label.new()", self.huella_vida)
        self.assertNotIn("porcentaje", self.huella_vida.lower())
        self.assertNotIn("nivel_economico", self.huella_vida.lower())

    def test_bombilla_fundida_bloquea_la_lampara_real(self):
        self.assertIn("func establecer_averiada(valor: bool)", self.lampara)
        self.assertIn("if _averiada:", self.lampara)
        self.assertIn('lampara.has_method("establecer_averiada")', self.consecuencias)
        self.assertIn("lampara.establecer_averiada(true)", self.consecuencias)

    def test_controller_deriva_desde_estado_oficial(self):
        self.assertIn('fase != "casa"', self.controller)
        self.assertIn('partida.estado.get("inventario", {})', self.controller)
        self.assertIn("CasaEstadoAmbientalScript.derivar", self.controller)
        self.assertIn("CasaAcumulacion.montar", self.controller)
        self.assertIn("CasaAcumulacion.firma", self.controller)
        self.assertIn("CasaConsecuencias.firma", self.controller)
        self.assertIn("CasaConsecuencias.montar", self.controller)
        self.assertIn("CasaHuellaVida.firma", self.controller)
        self.assertIn("CasaHuellaVida.montar", self.controller)
        self.assertNotIn("Inventario.recoger", self.controller)
        self.assertNotIn("Inventario.guardar_en_casa", self.controller)

    def test_dia_monta_controller_hijo_sin_reemplazar_raiz(self):
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)
        self.assertIn('path="res://guion/dia_acumulacion_casa_app.gd" id="22"', self.escena)
        self.assertIn('[node name="AcumulacionCasaController" type="Node" parent="."]', self.escena)
        self.assertIn('script = ExtResource("22")', self.escena)

    def test_vertical_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importacion = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--editor",
                "--import",
                "--quit",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(importacion.returncode, 0, importacion.stdout)

        for prueba, minimo in (
            (PRUEBA_GODOT, 40),
            (PRUEBA_CONSECUENCIAS, 15),
            (PRUEBA_HUELLA_VIDA, 15),
        ):
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    prueba,
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
            self.assertGreaterEqual(int(resumen.group(1)), minimo, resultado.stdout)
            self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
            self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
