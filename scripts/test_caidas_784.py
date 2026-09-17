from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
GEOMETRIA = ROOT / "godot" / "guion" / "sueno_geometria.gd"
DIA_CAIDAS = ROOT / "godot" / "guion" / "dia_caidas_app.gd"
DIA_CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
ESCENA_DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class Caidas784Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.geometria = GEOMETRIA.read_text(encoding="utf-8")
        cls.dia_caidas = DIA_CAIDAS.read_text(encoding="utf-8")
        cls.dia_calle = DIA_CALLE.read_text(encoding="utf-8")
        cls.escena_dia = ESCENA_DIA.read_text(encoding="utf-8")

    def test_trimesh_poligonal_colisiona_desde_el_interior(self):
        self.assertIn("var forma := malla.create_trimesh_shape()", self.geometria)
        self.assertIn("forma.backface_collision = true", self.geometria)
        self.assertIn("colision.shape = forma", self.geometria)

    def test_caida_profunda_reutiliza_el_contrato_de_situar(self):
        self.assertIn("const UMBRAL_RESCATE_CAIDA := -8.0", self.dia_caidas)
        self.assertIn("_caminante.position.y >= UMBRAL_RESCATE_CAIDA", self.dia_caidas)
        self.assertIn('_espacio_actual.get("entrada", Vector3.ZERO)', self.dia_caidas)
        self.assertIn("_caminante.situar(entrada", self.dia_caidas)

    def test_salida_disparada_en_fisica_sale_del_callback_antes_de_transicionar(self):
        self.assertIn("Engine.is_in_physics_frame()", self.dia_caidas)
        self.assertIn("await get_tree().process_frame", self.dia_caidas)
        self.assertNotIn('call_deferred("_al_pisar_salida"', self.dia_caidas)
        self.assertIn("super._al_pisar_salida(cuerpo, salida)", self.dia_caidas)

    def test_cadena_real_activa_la_capa_sin_sustituir_la_raiz_historica(self):
        self.assertIn('extends "res://guion/dia_caidas_app.gd"', self.dia_calle)
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', self.dia_caidas)
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena_dia)
        self.assertNotIn('path="res://guion/dia_caidas_app.gd" id="1"', self.escena_dia)

    def test_suelos_rescate_y_reentrada_se_ejecutan_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/prueba_caidas_784.gd",
            "Caídas #784: OK",
            timeout=60,
        )


if __name__ == "__main__":
    unittest.main()
