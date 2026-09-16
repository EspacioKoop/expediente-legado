from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MONTANA = ROOT / "godot" / "guion" / "sueno_montana.gd"
DIA_SUENO = ROOT / "godot" / "guion" / "dia_sueno_app.gd"


class SuenoMontanaRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.montana = MONTANA.read_text(encoding="utf-8")
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")

    def test_reutiliza_embudo_y_familia_convergente(self):
        self.assertIn('const FORMA := "embudo"', self.montana)
        self.assertIn("const FAMILIA := SuenoFamilias.CONVERGENTE", self.montana)
        self.assertIn("static func es_forma(id: String) -> bool:", self.montana)

    def test_transforma_solo_contenido_ya_autorizado(self):
        self.assertIn('resultado.get("carteles", [])', self.montana)
        self.assertIn("carteles.pop_front()", self.montana)
        self.assertIn('frase_conocida = String(primero.get("texto", ""))', self.montana)
        self.assertIn('"frase": frase_conocida', self.montana)
        self.assertIn('"destino": ""', self.montana)

    def test_cubre_cuatro_tipos_de_extraneza(self):
        for clave in (
            '"cabana_perspectiva"',
            '"huellas_anticipadas"',
            '"crujidos_sin_fuente"',
            '"documento_hielo"',
        ):
            self.assertIn(clave, self.montana)
        self.assertIn('resultado["montana_hielo_pos"]', self.montana)

    def test_no_muta_estado_jugable_ni_introduce_azar_global(self):
        codigo = self.montana.split("class_name SuenoMontana", 1)[1]
        for termino in ("Jornada.", "Partida.", "dinero", "veredicto", "randf(", "randi("):
            self.assertNotIn(termino, codigo)

    def test_capa_de_noche_adapta_despues_del_contenido_base(self):
        self.assertIn("var espacio: Dictionary = super._espacio_de(fase)", self.dia)
        self.assertIn("SuenoMontana.es_forma(id)", self.dia)
        self.assertIn("SuenoMontana.adaptar_espacio(espacio", self.dia)
        self.assertNotIn("Sueno.noche(", self.montana)


if __name__ == "__main__":
    unittest.main()
