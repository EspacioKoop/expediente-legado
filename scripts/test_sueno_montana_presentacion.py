from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRESENTACION = ROOT / "godot" / "guion" / "sueno_montana_3d.gd"
AUDIO = ROOT / "godot" / "guion" / "sueno_montana_audio.gd"
CABANA = ROOT / "godot" / "escenas" / "suenos" / "props_284" / "cabana_nieve.tscn"
CABANA_OBJ = ROOT / "godot" / "escenas" / "suenos" / "props_284" / "cabana_nieve_psx.obj"
DIA_SUENO = ROOT / "godot" / "guion" / "dia_sueno_app.gd"


class SuenoMontanaPresentacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.audio = AUDIO.read_text(encoding="utf-8")
        cls.cabana = CABANA.read_text(encoding="utf-8")
        cls.cabana_obj = CABANA_OBJ.read_text(encoding="utf-8")
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")

    def test_cabana_deja_de_ser_arquitectura_de_cajas(self):
        self.assertIn("cabana_nieve_psx.obj", self.cabana)
        self.assertNotIn('type="BoxMesh"', self.cabana)
        self.assertNotIn('type="CylinderMesh"', self.cabana)
        self.assertIn("o CabanaNievePSX", self.cabana_obj)
        self.assertGreater(self.cabana_obj.count("\nf "), 20)

    def test_cima_se_reconoce_como_exterior(self):
        for contrato in (
            "Geometry2D.triangulate_polygon(contorno)",
            'cima.name = "CimaNevada"',
            'roca.name = "LaderasDeLaCima"',
            'nube.name = "MarDeNubes"',
            'grupo.name = "HuellasAnticipadas"',
            'hielo.name = "DocumentoCongelado"',
        ):
            self.assertIn(contrato, self.presentacion)

    def test_cabana_cambia_solo_fuera_del_campo_frontal(self):
        self.assertIn("get_viewport().get_camera_3d()", self.presentacion)
        self.assertIn("visible_aprox", self.presentacion)
        self.assertIn("if not visible_aprox and not _estaba_fuera_de_vista", self.presentacion)
        self.assertIn("CABANA_LEJOS if _cabana_lejos else CABANA_CERCA", self.presentacion)

    def test_presentacion_no_duplica_fisica(self):
        self.assertNotIn("CollisionShape3D.new", self.presentacion)
        self.assertNotIn("StaticBody3D.new", self.presentacion)
        self.assertIn('get_node_or_null("Malla")', self.presentacion)
        self.assertIn("visual.visible = false", self.presentacion)

    def test_audio_es_procedural_y_determinista(self):
        self.assertIn("AudioStreamWAV.new()", self.audio)
        self.assertIn("const CRUJIDOS", self.audio)
        self.assertIn("1103515245", self.audio)
        self.assertNotIn("res://assets/audio", self.audio)
        self.assertNotIn("load(", self.audio)
        self.assertIn('crujidos.name = "CrujidosTrasPuerta"', self.presentacion)

    def test_runtime_nocturno_monta_montana_por_identidad(self):
        self.assertIn("SuenoMontana3D.montar(_mundo, _espacio_actual)", self.dia)
        self.assertIn('espacio.get("identidad_onirica", "")', self.presentacion)
        for termino in ("Partida", "Jornada", "veredicto", "dinero"):
            self.assertNotIn(termino, self.presentacion)


if __name__ == "__main__":
    unittest.main()
