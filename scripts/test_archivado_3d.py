from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot" / "guion" / "dia_archivado_app.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
CARPETA = ROOT / "godot" / "guion" / "carpeta_archivable_3d.gd"
TEXTOS = ROOT / "godot" / "datos" / "archivado_textos.json"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class Archivado3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.carpeta = CARPETA.read_text(encoding="utf-8")
        cls.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_conserva_la_raiz_historica_del_dia(self):
        self.assertIn('path="res://guion/dia_clima_app.gd"', self.escena)
        self.assertIn("ArchivadoSesion3D.new()", self.dia)
        self.assertIn("_archivado_sesion.refrescar(self)", self.dia)

    def test_solo_aparece_una_carpeta_conocida(self):
        self.assertIn("Archivado.es_clasificable", self.controlador)
        self.assertIn('jornada.get("leido_hoy", [])', self.controlador)
        self.assertIn("_primer_caso_clasificable", self.controlador)

    def test_reutiliza_el_motor_de_archivado(self):
        self.assertIn("ArchivadoBandeja.nueva", self.controlador)
        self.assertIn("ArchivadoBandeja.colocar", self.controlador)
        self.assertIn("Archivado.destino_de", self.controlador)

    def test_la_carpeta_es_un_objeto_3d_cogible(self):
        self.assertIn("extends Interactuable3D", self.carpeta)
        self.assertIn("Verbo.COGER", self.carpeta)
        self.assertIn("BoxMesh.new()", self.carpeta)
        self.assertIn("Label3D.new()", self.carpeta)
        self.assertIn('get_node_or_null("Camara")', self.carpeta)

    def test_destino_incorrecto_no_destruye_la_carpeta(self):
        bloque = self.controlador.split("if not correcta:", 1)[1].split("\n\n", 1)[0]
        self.assertNotIn("queue_free", bloque)
        self.assertIn('_texto("destino_incorrecto")', bloque)
        self.assertIn("sigue en tu mano", self.textos["destino_incorrecto"])

    def test_no_introduce_recompensas(self):
        texto = (self.controlador + self.carpeta).lower()
        for termino in [
            'jornada["dinero"]',
            'jornada["acciones"]',
            "pistas_descubiertas",
            "vida +=",
        ]:
            self.assertNotIn(termino, texto)


if __name__ == "__main__":
    unittest.main()
