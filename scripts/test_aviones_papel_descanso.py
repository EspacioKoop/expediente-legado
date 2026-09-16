from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
REGLA = ROOT / "godot" / "guion" / "aviones_papel_descanso.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "minijuego_aviones_papel_jornada.gd"
ESCENA = ROOT / "godot" / "escenas" / "minijuego_aviones_papel_jornada.tscn"
CUNADO = ROOT / "godot" / "guion" / "cunado.gd"


def sin_comentarios(fuente):
    """Quita los comentarios GDScript para comprobar solo el código ejecutable."""
    return "\n".join(linea.split("#", 1)[0] for linea in fuente.splitlines())


class AvionesPapelDescansoTest(unittest.TestCase):
    def setUp(self):
        self.regla = REGLA.read_text(encoding="utf-8")
        self.adaptador = ADAPTADOR.read_text(encoding="utf-8")
        self.escena = ESCENA.read_text(encoding="utf-8")
        self.cunado = CUNADO.read_text(encoding="utf-8")

    def test_aparicion_es_determinista_y_no_diaria(self):
        self.assertIn("const CICLO_APARICION := 3", self.regla)
        self.assertIn('jornada.get("fase", "") != "archivo"', self.regla)
        self.assertIn("raiz + vuelta + dia", self.regla)
        self.assertNotIn("randf", self.regla)
        self.assertNotIn("randi", self.regla)

    def test_recarga_no_repite_la_misma_oportunidad(self):
        self.assertIn('const CLAVE_ULTIMO_DIA := "aviones_papel_ultimo_dia"', self.regla)
        self.assertIn("jornada[CLAVE_ULTIMO_DIA]", self.regla)
        self.assertIn("marcar_jugado(jornada)", self.regla)

    def test_descanso_no_gasta_acciones_ni_concede_recursos(self):
        codigo = sin_comentarios(self.regla)
        for prohibido in (
            "Jornada.gastar_accion",
            'jornada["acciones"] -=',
            'jornada["dinero"]',
            "registrar_sello(",
            "pistas_descubiertas",
        ):
            self.assertNotIn(prohibido, codigo)

    def test_comentario_reutiliza_la_guarda_del_cunado(self):
        self.assertIn("Cunado.POR_MOMENTO", self.regla)
        self.assertIn("Cunado.todas_las_frases()", self.regla)
        self.assertIn("palabras_prohibidas()", self.regla)
        self.assertIn("static func todas_las_frases()", self.cunado)
        self.assertIn("static func palabras_prohibidas()", self.cunado)

    def test_adaptador_no_duplica_el_minijuego(self):
        self.assertIn('path="res://escenas/minijuego_aviones_papel.tscn"', self.escena)
        self.assertIn("minijuego.finalizada.connect(_al_finalizar)", self.adaptador)
        self.assertIn("AvionesPapelDescanso.finalizar(jornada, resultado)", self.adaptador)
        self.assertNotIn("AvionesPapel.lanzar(", self.adaptador)


if __name__ == "__main__":
    unittest.main()
