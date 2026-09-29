from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VENTANA = ROOT / "godot" / "guion" / "ventana_floja_oficina_1773.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_ventana_floja_app.gd"
SCENE = ROOT / "godot" / "escenas" / "dia.tscn"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class VentanaFloja1773Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ventana = VENTANA.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.scene = SCENE.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")

    def test_resuelve_estabilizar_por_contrato_semantico(self):
        self.assertIn("UsosHerramienta.ESTABILIZAR", self.ventana)
        self.assertIn("UsosHerramienta.resolver(_inventario, USO_REQUERIDO)", self.ventana)
        self.assertNotIn("palanca_kkryy", self.ventana)
        self.assertNotIn("linterna_kkryy", self.ventana)
        self.assertNotIn("cuna_imposible", self.ventana)

    def test_controller_usa_inventario_real_y_ventana_real(self):
        self.assertIn('partida.estado.get("inventario", {})', self.controller)
        self.assertIn('EspaciosCatalogo.OFICINA.get("ventanas", [])', self.controller)
        self.assertIn('jornada.get("fase", "")', self.controller)
        self.assertIn('!= "archivo"', self.controller)
        self.assertNotIn("Inventario.HOME_STORAGE", self.controller)
        self.assertNotIn("Inventario.recoger", self.controller)
        self.assertNotIn("Inventario.vender", self.controller)

    def test_estado_es_local_a_jornada_y_no_bloquea_ruta(self):
        self.assertIn('CLAVE_JORNADA := "ventana_floja_estabilizada_1773"', self.controller)
        self.assertIn("dia.jornada[CLAVE_JORNADA] = true", self.controller)
        self.assertNotIn("Jornada.gastar", self.controller)
        self.assertNotIn("acciones", self.controller)
        self.assertNotIn("pista", self.controller)
        self.assertNotIn("veredicto", self.controller)
        self.assertNotIn("NavigationObstacle3D", self.ventana)
        self.assertNotIn("StaticBody3D", self.ventana)

    def test_runtime_esta_montado_y_tiene_feedback_localizado(self):
        self.assertIn('res://guion/dia_ventana_floja_app.gd', self.scene)
        self.assertIn('name="VentanaFloja1773Controller"', self.scene)
        for clave in (
            "VENTANA_FLOJA_OFICINA",
            "VENTANA_FLOJA_FALTA_CALZO",
            "VENTANA_FLOJA_ESTABILIZADA",
        ):
            self.assertIn(clave + ",", self.textos)


if __name__ == "__main__":
    unittest.main()
