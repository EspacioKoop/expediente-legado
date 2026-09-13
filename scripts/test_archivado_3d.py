from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "dia_archivado_app.gd"
CARPETA = ROOT / "godot" / "guion" / "carpeta_archivable_3d.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class Archivado3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.capa = CAPA.read_text(encoding="utf-8")
        cls.carpeta = CARPETA.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_la_capa_conserva_clima_y_interaccion_existentes(self):
        self.assertIn('extends "res://guion/dia_clima_app.gd"', self.capa)
        self.assertIn("res://guion/dia_archivado_app.gd", self.escena)

    def test_solo_aparece_una_carpeta_conocida(self):
        self.assertIn("Archivado.es_clasificable", self.capa)
        self.assertIn('jornada.get("leido_hoy", [])', self.capa)
        self.assertIn("_primer_caso_clasificable", self.capa)

    def test_reutiliza_el_motor_de_archivado(self):
        self.assertIn("ArchivadoBandeja.nueva", self.capa)
        self.assertIn("ArchivadoBandeja.colocar", self.capa)
        self.assertIn("Archivado.destino_de", self.capa)

    def test_la_carpeta_es_un_objeto_3d_cogible(self):
        self.assertIn("extends Interactuable3D", self.carpeta)
        self.assertIn("Verbo.COGER", self.carpeta)
        self.assertIn("BoxMesh.new()", self.carpeta)
        self.assertIn("Label3D.new()", self.carpeta)
        self.assertIn('get_node_or_null("Camara")', self.carpeta)

    def test_destino_incorrecto_no_destruye_la_carpeta(self):
        bloque = self.capa.split("if not correcta:", 1)[1].split("\n\n", 1)[0]
        self.assertNotIn("queue_free", bloque)
        self.assertIn("sigue en tu mano", bloque)

    def test_no_introduce_recompensas_ni_inventario_general(self):
        texto = (self.capa + self.carpeta).lower()
        for termino in [
            'jornada["dinero"]',
            'jornada["acciones"]',
            "pistas_descubiertas",
            "vida +=",
            "inventario",
        ]:
            self.assertNotIn(termino, texto)


if __name__ == "__main__":
    unittest.main()
