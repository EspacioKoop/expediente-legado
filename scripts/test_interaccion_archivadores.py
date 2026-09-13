from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
ARCHIVADOR = ROOT / "godot" / "guion" / "archivador_interactivo_3d.gd"
INTERACTUABLE = ROOT / "godot" / "guion" / "interactuable_3d.gd"
DETECTOR = ROOT / "godot" / "guion" / "detector_interaccion_3d.gd"


class InteraccionArchivadoresTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.archivador = ARCHIVADOR.read_text(encoding="utf-8")
        cls.interactuable = INTERACTUABLE.read_text(encoding="utf-8")
        cls.detector = DETECTOR.read_text(encoding="utf-8")

    def test_monta_solo_modelos_de_archivador_del_catalogo(self):
        self.assertIn('String(bulto.get("modelo", "")) != "bookcaseClosed"', self.dia)
        self.assertIn("archivador.position = bulto[\"pos\"]", self.dia)
        self.assertIn('archivador.configurar(bulto["tam"])', self.dia)

    def test_se_limita_al_archivo(self):
        self.assertIn('if fase == "archivo":', self.dia)
        self.assertIn("_montar_archivadores_interactivos", self.dia)

    def test_archivador_alterna_abrir_y_cerrar_con_feedback_visual(self):
        self.assertIn("extends Interactuable3D", self.archivador)
        self.assertIn("Verbo.ABRIR", self.archivador)
        self.assertIn("Verbo.CERRAR", self.archivador)
        self.assertIn("_cajon.visible = _abierto", self.archivador)
        self.assertIn("BoxMesh.new()", self.archivador)

    def test_contrato_declara_cerrar_y_refresca_prompt(self):
        self.assertIn("CERRAR", self.interactuable)
        self.assertIn('Verbo.CERRAR: "Cerrar"', self.interactuable)
        self.assertIn(
            "objetivo_cambiado.emit(_objetivo, _objetivo.texto_accion())",
            self.detector,
        )

    def test_no_introduce_estado_de_jornada_ni_inventario(self):
        combinado = self.archivador + self.detector
        for prohibido in (
            "Partida",
            "Jornada",
            "pistas_descubiertas",
            "inventario",
            "guardar(",
        ):
            self.assertNotIn(prohibido, combinado)


if __name__ == "__main__":
    unittest.main()
