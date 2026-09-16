from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRESENTACION = ROOT / "godot" / "guion" / "sueno_escuela_3d.gd"
AUDIO = ROOT / "godot" / "guion" / "sueno_escuela_audio.gd"
PUPITRE = ROOT / "godot" / "escenas" / "suenos" / "props_284" / "pupitre_escolar.tscn"
PUPITRE_OBJ = ROOT / "godot" / "escenas" / "suenos" / "props_284" / "pupitre_escolar_psx.obj"
TAQUILLAS = ROOT / "godot" / "escenas" / "suenos" / "props_284" / "taquillas_escolares.tscn"
TAQUILLAS_OBJ = ROOT / "godot" / "escenas" / "suenos" / "props_284" / "taquillas_escolares_psx.obj"
DIA_SUENO = ROOT / "godot" / "guion" / "dia_sueno_app.gd"


class SuenoEscuelaPresentacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.audio = AUDIO.read_text(encoding="utf-8")
        cls.pupitre = PUPITRE.read_text(encoding="utf-8")
        cls.pupitre_obj = PUPITRE_OBJ.read_text(encoding="utf-8")
        cls.taquillas = TAQUILLAS.read_text(encoding="utf-8")
        cls.taquillas_obj = TAQUILLAS_OBJ.read_text(encoding="utf-8")
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")

    def test_props_principales_dejan_de_ser_cajas_del_motor(self):
        self.assertIn("pupitre_escolar_psx.obj", self.pupitre)
        self.assertIn("taquillas_escolares_psx.obj", self.taquillas)
        self.assertNotIn('type="BoxMesh"', self.pupitre)
        self.assertNotIn('type="BoxMesh"', self.taquillas)
        self.assertIn("o PupitreEscolarPSX", self.pupitre_obj)
        self.assertIn("o TaquillasEscolaresPSX", self.taquillas_obj)
        self.assertGreater(self.pupitre_obj.count("\nf "), 30)
        self.assertGreater(self.taquillas_obj.count("\nf "), 30)

    def test_pasillos_se_redibujan_desde_la_misma_planta(self):
        for contrato in (
            "Planta.celdas(bloques)",
            "Planta.contorno(bloques)",
            '"LinoleoEscolar"',
            '"ZocaloEscolar"',
            '"ParedEscolar"',
            '"PizarraVacia"',
        ):
            self.assertIn(contrato, self.presentacion)

    def test_timbre_reordena_aulas_y_pupitres(self):
        self.assertIn("const INTERVALO_TIMBRE := 7.5", self.presentacion)
        self.assertIn("_variante = 1 - _variante", self.presentacion)
        self.assertIn("var posiciones_a := [", self.presentacion)
        self.assertIn("var posiciones_b := [", self.presentacion)
        self.assertIn("_numeros[i].text = str(", self.presentacion)
        self.assertIn("_pupitres[i].rotation_degrees.y", self.presentacion)
        self.assertIn("_timbre.play()", self.presentacion)

    def test_reloj_y_dibujo_tienen_anomalia_temporal_y_objeto(self):
        self.assertIn('reloj.name = "RelojTresAgujas"', self.presentacion)
        self.assertIn('get_node_or_null("AgujaFantasma")', self.presentacion)
        self.assertIn("_reloj_fantasma.rotation_degrees.z -=", self.presentacion)
        self.assertIn('_dibujo.name = "DibujoMutante"', self.presentacion)

    def test_presentacion_no_duplica_fisica(self):
        self.assertNotIn("CollisionShape3D.new", self.presentacion)
        self.assertNotIn("StaticBody3D.new", self.presentacion)
        self.assertIn('find_children("*", "MeshInstance3D"', self.presentacion)
        self.assertIn("visual.visible = false", self.presentacion)

    def test_audio_es_procedural_determinista_y_sin_voces_reales(self):
        self.assertIn("AudioStreamWAV.new()", self.audio)
        self.assertIn("1103515245", self.audio)
        self.assertIn("static func timbre()", self.audio)
        self.assertIn("static func voces_vacias()", self.audio)
        self.assertNotIn("res://assets/audio", self.audio)
        self.assertNotIn("load(", self.audio)
        self.assertIn('timbre.name = "TimbreFueraDeHorario"', self.presentacion)
        self.assertIn('voces.name = "VocesAulaVacia"', self.presentacion)

    def test_runtime_nocturno_monta_escuela_por_identidad(self):
        self.assertIn("SuenoEscuela3D.montar(_mundo, _espacio_actual)", self.dia)
        self.assertIn('espacio.get("identidad_onirica", "")', self.presentacion)
        for termino in ("Partida", "Jornada", "veredicto", "dinero"):
            self.assertNotIn(termino, self.presentacion)


if __name__ == "__main__":
    unittest.main()
