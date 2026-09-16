from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ESCUELA = ROOT / "godot" / "guion" / "sueno_escuela.gd"
DIA_SUENO = ROOT / "godot" / "guion" / "dia_sueno_app.gd"


class SuenoEscuelaRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.escuela = ESCUELA.read_text(encoding="utf-8")
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")

    def test_reutiliza_crucero_sin_reseleccionar_la_noche(self):
        self.assertIn('const FORMA := "crucero"', self.escuela)
        self.assertIn("static func es_forma(id: String) -> bool:", self.escuela)
        self.assertNotIn("Sueno.noche(", self.escuela)

    def test_dibujo_reutiliza_contenido_ya_conocido_sin_consumirlo(self):
        self.assertIn('resultado.get("carteles", [])', self.escuela)
        self.assertIn("var primero: Dictionary = carteles[0]", self.escuela)
        self.assertNotIn("carteles.pop_front()", self.escuela)
        self.assertIn('frase_conocida = String(primero.get("texto", ""))', self.escuela)
        self.assertIn('"frase": frase_conocida', self.escuela)
        self.assertIn('"destino": ""', self.escuela)

    def test_cubre_extraneza_escolar_propia(self):
        for clave in (
            '"aulas_reordenadas"',
            '"timbre_fuera_horario"',
            '"pupitres_pared_vacia"',
            '"voces_aula_vacia"',
            '"dibujo_mutante"',
            '"reloj_tres_agujas"',
        ):
            self.assertIn(clave, self.escuela)

    def test_no_muta_estado_jugable_ni_usa_azar_global(self):
        codigo = self.escuela.split("class_name SuenoEscuela", 1)[1]
        for termino in ("Jornada.", "Partida.", "dinero", "veredicto", "randf(", "randi("):
            self.assertNotIn(termino, codigo)

    def test_capa_nocturna_adapta_despues_del_contenido_base(self):
        self.assertIn("var espacio: Dictionary = super._espacio_de(fase)", self.dia)
        self.assertIn("SuenoEscuela.es_forma(id)", self.dia)
        self.assertIn("SuenoEscuela.adaptar_espacio(espacio", self.dia)
        self.assertIn("SuenoEscuela3D.montar(_mundo, _espacio_actual)", self.dia)


if __name__ == "__main__":
    unittest.main()
