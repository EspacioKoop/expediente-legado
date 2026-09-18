from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRESENTACION = ROOT / "godot" / "guion" / "sueno_desierto_3d.gd"
AUDIO = ROOT / "godot" / "guion" / "sueno_desierto_audio.gd"
PROPS = ROOT / "godot" / "escenas" / "suenos" / "props_284"
TELEFONO = PROPS / "cabina_telefono_desierto.tscn"
TELEFONO_OBJ = PROPS / "cabina_telefono_desierto_psx.obj"
ARCHIVADOR = PROPS / "archivador_desierto.tscn"
ARCHIVADOR_OBJ = PROPS / "archivador_desierto_psx.obj"
DIA_SUENO = ROOT / "godot" / "guion" / "dia_sueno_app.gd"


class SuenoDesiertoPresentacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.audio = AUDIO.read_text(encoding="utf-8")
        cls.telefono = TELEFONO.read_text(encoding="utf-8")
        cls.telefono_obj = TELEFONO_OBJ.read_text(encoding="utf-8")
        cls.archivador = ARCHIVADOR.read_text(encoding="utf-8")
        cls.archivador_obj = ARCHIVADOR_OBJ.read_text(encoding="utf-8")
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")

    def test_props_dejan_de_depender_de_boxmesh(self):
        self.assertIn("cabina_telefono_desierto_psx.obj", self.telefono)
        self.assertIn("archivador_desierto_psx.obj", self.archivador)
        self.assertNotIn('type="BoxMesh"', self.telefono)
        self.assertNotIn('type="BoxMesh"', self.archivador)
        self.assertIn("o CabinaTelefonoDesiertoPSX", self.telefono_obj)
        self.assertIn("o ArchivadorDesiertoPSX", self.archivador_obj)
        self.assertGreater(self.telefono_obj.count("\nf "), 30)
        self.assertGreater(self.archivador_obj.count("\nf "), 20)

    def test_desierto_se_reconoce_sin_hud(self):
        for contrato in (
            'suelo.name = "ArenaCaminable"',
            'dunas.name = "HorizonteDeDunas"',
            'grupo.name = "HuellasGeometricas"',
            'sombra.name = "SombraSinObjeto"',
            '_papel.name = "PapelSemienterrado"',
            'telefono.name = "TelefonoAislado"',
            'archivador.name = "ArchivadorAislado"',
        ):
            self.assertIn(contrato, self.presentacion)

    def test_horizonte_es_visible_desde_el_interior_del_anillo(self):
        self.assertIn("material_dunas.cull_mode = BaseMaterial3D.CULL_DISABLED", self.presentacion)
        self.assertIn("dunas.material_override = material_dunas", self.presentacion)
        self.assertIn("Color(0.42, 0.25, 0.12)", self.presentacion)

    def test_horizonte_retrocede_y_hay_zona_de_silencio(self):
        self.assertIn("get_viewport().get_camera_3d()", self.presentacion)
        self.assertIn("direccion * RADIO_HORIZONTE", self.presentacion)
        self.assertIn("CENTRO_SILENCIO", self.presentacion)
        self.assertIn("RADIO_SILENCIO", self.presentacion)
        self.assertIn("-80.0 if en_silencio", self.presentacion)

    def test_presentacion_no_duplica_fisica(self):
        self.assertNotIn("CollisionShape3D.new", self.presentacion)
        self.assertNotIn("StaticBody3D.new", self.presentacion)
        self.assertIn('get_node_or_null("Malla")', self.presentacion)
        self.assertIn("visual.visible = false", self.presentacion)

    def test_audio_es_procedural_y_determinista(self):
        self.assertIn("AudioStreamWAV.new()", self.audio)
        self.assertIn("const GOLPES_OFICINA", self.audio)
        self.assertIn("1664525", self.audio)
        self.assertIn("350.0", self.audio)
        self.assertIn("440.0", self.audio)
        self.assertNotIn("res://assets/audio", self.audio)
        self.assertNotIn("load(", self.audio)
        self.assertIn('name = "VientoConOficina"', self.presentacion)
        self.assertIn('name = "TonoSinLinea"', self.presentacion)

    def test_runtime_nocturno_monta_desierto_por_identidad(self):
        self.assertIn("SuenoDesierto3D.montar(_mundo, _espacio_actual)", self.dia)
        self.assertIn('espacio.get("identidad_onirica", "")', self.presentacion)
        for termino in ("Partida", "Jornada", "veredicto", "dinero"):
            self.assertNotIn(termino, self.presentacion)


if __name__ == "__main__":
    unittest.main()
