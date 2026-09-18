from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
AUDIO = RAIZ / "godot" / "guion" / "sueno_castillo_audio.gd"
PRESENTACION = RAIZ / "godot" / "guion" / "sueno_castillo_3d.gd"
PULSO = RAIZ / "godot" / "guion" / "sueno_castillo_pulso_3d.gd"
UMBRALES = RAIZ / "godot" / "guion" / "sueno_castillo_umbrales_3d.gd"
DIA_SUENO = RAIZ / "godot" / "guion" / "dia_sueno_app.gd"
PATIO = RAIZ / "godot" / "escenas" / "suenos" / "props_284" / "patio_castillo_onirico.tscn"
SCRIPTORIUM = RAIZ / "godot" / "escenas" / "suenos" / "props_284" / "galeria_scriptorium_castillo.tscn"
TORRE = RAIZ / "godot" / "escenas" / "suenos" / "props_284" / "torre_capilla_castillo.tscn"
CLAUSTRO = RAIZ / "godot" / "escenas" / "suenos" / "props_284" / "claustro_reflejado_castillo.tscn"
ARCADA = RAIZ / "godot" / "escenas" / "suenos" / "props_284" / "arcada_claustro_castillo_psx.obj"
TORRE_OBJ = RAIZ / "godot" / "escenas" / "suenos" / "props_284" / "torre_castillo_psx.obj"


class SuenoCastilloPresentacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.audio = AUDIO.read_text(encoding="utf-8")
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.pulso = PULSO.read_text(encoding="utf-8")
        cls.umbrales = UMBRALES.read_text(encoding="utf-8")
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")
        cls.patio = PATIO.read_text(encoding="utf-8")
        cls.scriptorium = SCRIPTORIUM.read_text(encoding="utf-8")
        cls.torre = TORRE.read_text(encoding="utf-8")
        cls.claustro = CLAUSTRO.read_text(encoding="utf-8")
        cls.arcada = ARCADA.read_text(encoding="utf-8")
        cls.torre_obj = TORRE_OBJ.read_text(encoding="utf-8")

    def test_campanas_son_procedurales_deterministas_y_sin_binarios(self):
        self.assertIn("AudioStreamWAV.new()", self.audio)
        self.assertIn("LOOP_FORWARD", self.audio)
        self.assertIn("const CAMPANADAS := [0.35, 2.25, 4.65]", self.audio)
        for aleatorio in ("randf(", "randi(", "randomize("):
            self.assertNotIn(aleatorio, self.audio)
        self.assertNotIn("res://assets/audio/", self.audio)

    def test_presentacion_reutiliza_patio_mergeado_y_audio_3d(self):
        self.assertIn("patio_castillo_onirico.tscn", self.presentacion)
        self.assertIn("AudioStreamPlayer3D.new()", self.presentacion)
        self.assertIn("SuenoCastilloAudio.campanadas()", self.presentacion)
        self.assertIn('campanas.name = "CampanasSinFuente"', self.presentacion)

    def test_presentacion_selecciona_cuatro_composiciones_propias(self):
        self.assertIn("galeria_scriptorium_castillo.tscn", self.presentacion)
        self.assertIn("torre_capilla_castillo.tscn", self.presentacion)
        self.assertIn("claustro_reflejado_castillo.tscn", self.presentacion)
        self.assertIn('espacio.get("variante_castillo", "patio")', self.presentacion)
        self.assertIn('"scriptorium":', self.presentacion)
        self.assertIn('"torre_capilla":', self.presentacion)
        self.assertIn('"claustro_reflejado":', self.presentacion)

    def test_composiciones_reutilizan_piezas_sin_fisica_paralela(self):
        self.assertIn("muro_torre_castillo.tscn", self.scriptorium)
        self.assertIn("escalera_anular_castillo.tscn", self.scriptorium)
        self.assertIn("arcada_claustro_castillo.tscn", self.torre)
        self.assertIn("torre_castillo.tscn", self.torre)
        self.assertIn("escalera_anular_castillo.tscn", self.torre)
        self.assertIn("arcada_claustro_castillo.tscn", self.claustro)
        self.assertIn("escalera_anular_castillo.tscn", self.claustro)
        for escena in (self.scriptorium, self.torre, self.claustro):
            self.assertNotIn("StaticBody3D", escena)
            self.assertNotIn("CollisionShape3D", escena)
            self.assertNotIn("BoxMesh", escena)
            self.assertNotIn("CylinderMesh", escena)
        self.assertIn("AtrilCodice", self.scriptorium)
        self.assertIn("EscaleraAlta", self.torre)
        self.assertIn("LuzAltaImposible", self.torre)
        self.assertIn("TorreCampanario", self.torre)
        self.assertIn("TorreEco", self.torre)
        self.assertNotIn("muro_torre_castillo.tscn", self.torre)
        self.assertIn("ArcadaOesteElevada", self.claustro)
        self.assertIn("EscaleraReflejoB", self.claustro)

    def test_arcada_de_claustro_deriva_del_modelo_propio_sin_torres(self):
        self.assertIn("o ArcadaClaustroPSX", self.arcada)
        self.assertIn("g Arch_00", self.arcada)
        self.assertIn("g Arch_10", self.arcada)
        for grupo in ("g Tower_L", "g Roof_L", "g Tower_R", "g Roof_R", "g ButtressL", "g ButtressR"):
            self.assertNotIn(grupo, self.arcada)

    def test_torre_autonoma_deriva_del_modelo_propio_sin_portal(self):
        self.assertIn("o TorreCastilloPSX", self.torre_obj)
        self.assertIn("g Tower", self.torre_obj)
        self.assertIn("g Roof", self.torre_obj)
        self.assertIn("g ArrowSlit", self.torre_obj)
        for grupo in ("g WallLeft", "g WallRight", "g WallCrown", "g Arch_00", "g ButtressL"):
            self.assertNotIn(grupo, self.torre_obj)

    def test_mutacion_secundaria_deforma_presentacion_sin_tocar_fisica(self):
        self.assertIn('espacio.get("mutacion_castillo", "estable")', self.presentacion)
        self.assertIn("static func _aplicar_mutacion(", self.presentacion)
        for mutacion in ('"desfase":', '"contraccion":', '"giro":'):
            self.assertIn(mutacion, self.presentacion)
        self.assertIn("arquitectura.scale = Vector3(0.92, 1.12, 0.92)", self.presentacion)

    def test_pulsos_solo_transforman_piezas_marcadas_y_reutilizan_campanadas(self):
        self.assertIn('const GRUPO_ANOMALIA := "castillo_anomalia"', self.pulso)
        self.assertIn('is_in_group(GRUPO_ANOMALIA)', self.pulso)
        self.assertIn("SuenoCastilloAudio.CAMPANADAS", self.pulso)
        self.assertIn("SuenoCastilloAudio.DURACION", self.pulso)
        self.assertIn("func aplicar_pulso(indice: int) -> void:", self.pulso)
        self.assertIn('pulso.name = "PulsoArquitectonico"', self.presentacion)
        self.assertIn("pulso.configurar(arquitectura, campanas)", self.presentacion)
        for termino in ("StaticBody3D", "CollisionShape3D", "Jornada.", "Partida"):
            self.assertNotIn(termino, self.pulso)

    def test_cada_composicion_declara_anomalias_sin_marcar_el_suelo(self):
        for escena in (self.patio, self.scriptorium, self.torre, self.claustro):
            self.assertIn('groups=["castillo_anomalia"]', escena)
        self.assertNotIn('[node name="SueloPatio" type="MeshInstance3D" parent="." groups=', self.patio)
        self.assertNotIn('[node name="SueloScriptorium" type="MeshInstance3D" parent="." groups=', self.scriptorium)
        self.assertNotIn('[node name="SueloCapilla" type="MeshInstance3D" parent="." groups=', self.torre)
        self.assertNotIn('[node name="SueloClaustro" type="MeshInstance3D" parent="." groups=', self.claustro)

    def test_umbrales_insinuan_otra_ala_sin_crear_navegacion(self):
        self.assertIn('const GRUPO_UMBRAL := "castillo_umbral"', self.umbrales)
        self.assertIn('"patio": "scriptorium"', self.umbrales)
        self.assertIn('"scriptorium": "claustro_reflejado"', self.umbrales)
        self.assertIn('"claustro_reflejado": "torre_capilla"', self.umbrales)
        self.assertIn('"torre_capilla": "patio"', self.umbrales)
        self.assertIn("SuenoCastilloUmbrales3D.montar(arquitectura, variante)", self.presentacion)
        for escena in (self.patio, self.scriptorium, self.torre, self.claustro):
            self.assertIn('groups=["castillo_umbral"]', escena)
        for pieza in (
            "muro_torre_castillo.tscn",
            "arcada_claustro_castillo.tscn",
            "torre_castillo.tscn",
            "escalera_anular_castillo.tscn",
            "estandarte_anular.tscn",
        ):
            self.assertIn(pieza, self.umbrales)
        for termino in ("StaticBody3D", "CollisionShape3D", "teleport", "Jornada.", "Partida"):
            self.assertNotIn(termino, self.umbrales)

    def test_presentacion_solo_se_activa_por_identidad_de_datos(self):
        self.assertIn('espacio.get("identidad_onirica", "")', self.presentacion)
        self.assertIn("SuenoCastillo.ID", self.presentacion)
        self.assertNotIn('id == "patio"', self.presentacion)

    def test_presentacion_no_duplica_fisica_ni_estado_de_juego(self):
        for termino in (
            "StaticBody3D",
            "CollisionShape3D",
            "BoxMesh",
            "Rect2i",
            "Jornada.",
            "Partida",
            "dinero",
            "veredicto",
        ):
            self.assertNotIn(termino, self.presentacion)

    def test_capa_de_sueno_monta_presentacion_despues_del_mundo_base(self):
        self.assertIn("func _entrar_en(fase: String) -> void:", self.dia)
        bloque = self.dia.split("func _entrar_en(fase: String) -> void:", 1)[1]
        self.assertLess(bloque.index("super._entrar_en(fase)"), bloque.index("SuenoCastillo3D.montar"))
        self.assertIn("SuenoCastillo3D.montar(_mundo, _espacio_actual)", bloque)
        self.assertNotIn('_espacio_actual["identidad_onirica"] =', bloque)


if __name__ == "__main__":
    unittest.main()
