from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ADAPTADOR = ROOT / "godot" / "guion" / "sueno_vacio.gd"
PRESENTACION = ROOT / "godot" / "guion" / "sueno_vacio_3d.gd"
AUDIO = ROOT / "godot" / "guion" / "sueno_vacio_audio.gd"
DIA = ROOT / "godot" / "guion" / "dia_sueno_app.gd"
CAPTURADOR = ROOT / "godot" / "pruebas" / "capturar_sueno_786.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "evidencia-sueno-786.yml"


class SuenoVacio786Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.adaptador = ADAPTADOR.read_text(encoding="utf-8")
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.audio = AUDIO.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.capturador = CAPTURADOR.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_cero_lecturas_tiene_identidad_explicita(self) -> None:
        self.assertIn('const ID := "vacio"', self.adaptador)
        self.assertIn('resultado["sueno_sin_lecturas"] = true', self.adaptador)
        self.assertIn('resultado["figuras"] = []', self.adaptador)
        self.assertIn('resultado["carteles"] = []', self.adaptador)
        self.assertIn("SuenoFamilias.FRAGMENTADA", self.adaptador)
        self.assertIn('resultado["tabiques_poligonales"]', self.adaptador)
        self.assertIn('jornada.get("leido_hoy", []).is_empty()', self.dia)
        self.assertIn("return SuenoVacio.adaptar_espacio(espacio)", self.dia)

    def test_no_pasa_por_identidades_que_inventen_escenografia(self) -> None:
        vacio = self.dia.index('jornada.get("leido_hoy", []).is_empty()')
        escuela = self.dia.index("SuenoEscuela.es_forma(id)")
        horror = self.dia.index("HorrorTexturas.aplicar")
        self.assertLess(vacio, escuela)
        self.assertLess(vacio, horror)

    def test_presentacion_convierte_greybox_en_ausencia_deliberada(self) -> None:
        for contrato in (
            "entorno.fog_enabled = true",
            "entorno.fog_density = DENSIDAD_NIEBLA",
            'suelo.name = "SueloOficinaAusente"',
            'borde.name = "PerimetroOficinaAusente"',
            'visual.visible = false',
            'grupo.name = "HuellasPuestosVacios"',
            'grupo.name = "EcosTabiquesOficina"',
            'grupo.name = "EcosMobiliarioOficina"',
            '"oficina_psx/desk1"',
            '"oficina_psx/office_chair_black"',
            '"oficina_psx/computer_monitor"',
            'grupo.name = "FluorescentesDesalineados"',
            'name = "ZumbidoOficinaVacia"',
        ):
            self.assertIn(contrato, self.presentacion)
        self.assertNotIn("BoxMesh.new()", self.presentacion)
        self.assertNotIn("CSGBox3D", self.presentacion)
        self.assertIn('espacio.get("tabiques_poligonales", [])', self.presentacion)

    def test_audio_es_procedural_y_no_carga_recuerdos(self) -> None:
        self.assertIn("AudioStreamWAV.new()", self.audio)
        self.assertIn("const PULSOS_RELE", self.audio)
        self.assertIn("50.0", self.audio)
        self.assertIn("100.0", self.audio)
        self.assertNotIn("load(", self.audio)
        self.assertNotIn("res://assets/audio", self.audio)

    def test_runtime_monta_presentacion_vacia(self) -> None:
        self.assertIn("SuenoVacio3D.montar(_mundo, _espacio_actual)", self.dia)
        self.assertIn('espacio.get("identidad_onirica", "")', self.presentacion)
        for termino in ("Partida", "Jornada", "dinero", "veredicto"):
            self.assertNotIn(termino, self.presentacion)

    def test_gate_visual_reproduce_exactamente_cero_lecturas(self) -> None:
        self.assertIn("SuenoVacio.adaptar_espacio(Sueno.espacio(FORMA, 0, {}))", self.capturador)
        self.assertIn('"leido_hoy": []', self.capturador)
        self.assertIn('"hud": false', self.capturador)
        self.assertIn('"entrada"', self.capturador)
        self.assertIn('"interior"', self.capturador)
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("entrada.png", self.workflow)
        self.assertIn("interior.png", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)


if __name__ == "__main__":
    unittest.main()
