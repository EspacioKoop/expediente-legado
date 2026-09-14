from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MANDO = ROOT / "godot" / "guion" / "mando_television_98.gd"
TELEVISOR = ROOT / "godot" / "guion" / "television_interactiva_3d.gd"


class MandoTelevision98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mando = MANDO.read_text(encoding="utf-8")
        cls.televisor = TELEVISOR.read_text(encoding="utf-8")

    def test_es_interactuable_y_reconocible_como_mando_noventero(self):
        self.assertIn("extends Interactuable3D", self.mando)
        self.assertIn('nombre_objeto = "mando del televisor"', self.mando)
        self.assertIn("CollisionShape3D.new()", self.mando)
        self.assertIn("BoxMesh.new()", self.mando)
        self.assertIn("CylinderMesh.new()", self.mando)
        self.assertIn("for fila in range(3)", self.mando)
        self.assertIn("for columna in range(3)", self.mando)

    def test_el_mando_controla_el_estado_real_del_televisor(self):
        self.assertIn('has_method("alternar_desde_mando")', self.mando)
        self.assertIn('call("alternar_desde_mando")', self.mando)
        self.assertIn("func alternar_desde_mando()", self.televisor)
        self.assertIn("_alternar(null)", self.televisor)
        self.assertIn("_brillo.visible = _encendida", self.televisor)

    def test_el_televisor_monta_el_mando_en_el_rincon_de_ocio(self):
        self.assertIn("MandoTelevision98.new()", self.televisor)
        self.assertIn('mando.name = "MandoTelevision98"', self.televisor)
        self.assertIn("Vector3(1.25, 0.23, -1.18)", self.televisor)
        self.assertIn("mando.configurar(self)", self.televisor)

    def test_no_inventa_funciones_que_la_tele_no_tiene(self):
        for termino in (
            "cambiar_canal",
            "subir_volumen",
            "bajar_volumen",
            "canal_actual",
            "volumen_actual",
        ):
            self.assertNotIn(termino, self.mando)

    def test_no_toca_estado_de_campana_ni_assets_externos(self):
        combinado = self.mando + self.televisor
        for termino in (
            "Partida.",
            "Jornada.",
            "pistas_descubiertas",
            "inventario",
            "dinero",
            "guardar(",
            "preload(",
            ".glb",
            ".png",
        ):
            self.assertNotIn(termino, combinado)


if __name__ == "__main__":
    unittest.main()
