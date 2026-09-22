from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
SUENO = RAIZ / "godot" / "guion" / "sueno_aquiles.gd"
ESCENA = RAIZ / "godot" / "escenas" / "sueno_aquiles.tscn"
CATALOGO = RAIZ / "docs" / "assets" / "aquiles-cc0.md"


class SuenoAquilesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.catalogo = CATALOGO.read_text(encoding="utf-8")

    def test_semilla_exige_interaccion_deliberada(self):
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_aquiles"', self.sueno)
        self.assertIn("giros < GIROS_MINIMOS", self.sueno)
        self.assertIn("not talon_observado", self.sueno)
        self.assertIn("estado[CLAVE_SEMILLA] = true", self.sueno)

    def test_la_entrada_no_se_activa_sin_semilla(self):
        self.assertIn("static func puede_entrar", self.sueno)
        self.assertIn("estado.get(CLAVE_SEMILLA, false)", self.sueno)

    def test_vulnerabilidad_se_revela_por_lectura_espacial(self):
        self.assertIn("luz_alineada or reflejo_alineado", self.sueno)
        self.assertIn('ACCIONES_RESOLUCION := ["tocar", "sellar", "enfocar", "colocar"]', self.sueno)
        self.assertNotIn('"atacar"', self.sueno)
        self.assertNotIn('"golpear"', self.sueno)
        self.assertNotIn('"disparar"', self.sueno)

    def test_resolucion_transforma_sin_camara_forzada(self):
        self.assertIn('TRANSFORMACION := "papel_y_sellos"', self.sueno)
        self.assertIn('"sacudida_camara": false', self.sueno)
        self.assertIn('"flash": false', self.sueno)
        self.assertIn('"escala_progresiva_y_fundido"', self.sueno)
        self.assertIn('"MarcaSelladoFinal"', self.sueno)
        self.assertIn("_revestir_geometria(_figura, papel)", self.sueno)
        self.assertIn("tween.set_parallel(true)", self.sueno)

    def test_escena_standalone_usa_el_vertical(self):
        self.assertIn('path="res://guion/sueno_aquiles.gd"', self.escena)
        self.assertIn('[node name="SuenoAquiles" type="Node3D"]', self.escena)

    def test_modelo_cc0_tiene_fallback_y_no_es_dependencia_de_arranque(self):
        self.assertIn("ResourceLoader.exists(MODELO_CC0_RUTA)", self.sueno)
        self.assertIn("if not _montar_modelo_cc0():", self.sueno)
        self.assertIn("_montar_figura_fallback()", self.sueno)

    def test_catalogo_documenta_fuentes_cc0_2d_y_3d(self):
        self.assertIn("Achilles Spartan Greek Warrior", self.catalogo)
        self.assertIn("OpenGameArt", self.catalogo)
        self.assertIn("The Baptism of Achilles", self.catalogo)
        self.assertIn("Cleveland Museum of Art", self.catalogo)
        self.assertIn("Thetis Dipping the Infant Achilles", self.catalogo)
        self.assertIn("3d Greek Weapons Set", self.catalogo)
        self.assertIn("Modular Temple - 3D Models", self.catalogo)
        self.assertGreaterEqual(self.catalogo.count("CC0"), 8)

    def test_no_finge_binarios_que_aun_no_estan_vendorados(self):
        self.assertIn("El primer corte no incluye binarios", self.catalogo)
        self.assertIn("godot/assets/procedencia.json", self.catalogo)
        self.assertIn("Git LFS", self.catalogo)


if __name__ == "__main__":
    unittest.main()
