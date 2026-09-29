from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
CAMARA = ROOT / "godot" / "guion" / "camara_onirica_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
ESTADO = ROOT / "godot" / "guion" / "grabacion_onirica_estado.gd"


class CamaraOniricaFisica140Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.camara = CAMARA.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.estado = ESTADO.read_text(encoding="utf-8")

    def test_objeto_fisico_usa_interaccion_comun(self):
        self.assertIn("extends Interactuable3D", self.camara)
        self.assertIn("verbo = Verbo.COGER", self.camara)
        self.assertIn("CollisionShape3D.new()", self.camara)
        self.assertIn("CylinderMesh.new()", self.camara)
        self.assertNotIn("InputMap", self.camara)

    def test_adquisicion_crea_la_cinta_existente_no_estado_paralelo(self):
        self.assertIn("GrabacionOniricaEstado.iniciar_cinta(", self.controlador)
        self.assertIn("GrabacionOniricaEstado.asegurar_en_estado(", self.controlador)
        self.assertIn("CAPACIDAD_CINTA_SEGUNDOS := 10.0", self.controlador)
        self.assertNotIn('camara_onirica_adquirida"', self.controlador)
        self.assertNotIn('"camara_adquirida"', self.controlador)
        self.assertIn('const CLAVE_ESTADO := "grabacion_onirica"', self.estado)

    def test_grabacion_exige_adquisicion_y_conserva_runtime_existente(self):
        self.assertIn("ERROR_CAMARA_NO_ADQUIRIDA", self.controlador)
        self.assertIn("if not _camara_disponible(dia):", self.controlador)
        self.assertIn("_grabacion_runtime.iniciar(camara, anomalia, documento, true)", self.controlador)
        self.assertIn("_grabacion_runtime.muestrear(delta)", self.controlador)

    def test_hud_es_presentacion_y_muestra_metraje(self):
        self.assertIn("CanvasLayer.new()", self.controlador)
        self.assertIn('NOMBRE_HUD_CAMARA := "GrabacionOniricaHUD"', self.controlador)
        self.assertIn('cinta.get("metraje_restante", 0.0)', self.controlador)
        self.assertIn('"●" if grabacion_activa() else "○"', self.controlador)

    def test_contrato_ejecutable_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_camara_onirica_fisica_140.gd",
            "Cámara onírica física 140:",
        )


if __name__ == "__main__":
    unittest.main()
