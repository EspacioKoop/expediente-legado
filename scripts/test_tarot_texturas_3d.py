from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
TAROT = ROOT / "godot" / "guion" / "tarot_cinematica.gd"
PANTALLA = ROOT / "godot" / "guion" / "pantalla.gd"


class TarotTexturas3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tarot = TAROT.read_text(encoding="utf-8")
        cls.pantalla = PANTALLA.read_text(encoding="utf-8")

    def test_tarot_resuelve_frontal_por_id_canonico(self) -> None:
        self.assertIn('const RUTA_FRENTE := "res://assets/tarot/%s.png"', self.tarot)
        self.assertIn('decorado(String(carta.get("id", "")))', self.tarot)
        self.assertIn("RUTA_FRENTE % carta_id", self.tarot)
        self.assertIn("ResourceLoader.exists(ruta_frontal)", self.tarot)

    def test_asset_ausente_conserva_fallback_3d(self) -> None:
        self.assertIn('const FRENTE := Color("e8c46a")', self.tarot)
        self.assertIn('const FRENTE_MARCA := Color("8e2f4a")', self.tarot)
        self.assertIn("cara.call(GROSOR, Vector3(ancho, alto, 0.004), FRENTE, true)", self.tarot)
        self.assertIn("FRENTE_MARCA", self.tarot)
        self.assertIn('if not ruta_frontal.is_empty() and ResourceLoader.exists(ruta_frontal):', self.tarot)
        self.assertEqual(self.tarot.count('mesa["pantallas"] = ['), 1)

    def test_frontal_real_es_plano_uv_por_delante_de_la_carta(self) -> None:
        self.assertIn('"fichero": ruta_frontal', self.tarot)
        self.assertIn('"resolucion": RESOLUCION_FRENTE', self.tarot)
        self.assertIn('CENTRO + Vector3(0, 0, GROSOR + 0.006)', self.tarot)
        self.assertIn("RESOLUCION_FRENTE.x", self.tarot)
        self.assertIn("RESOLUCION_FRENTE.y", self.tarot)

    def test_pantalla_admite_texture2d_estatica_sin_romper_video(self) -> None:
        self.assertIn("if not _montar_video(vista, fichero) and not _montar_imagen(vista, fichero):", self.pantalla)
        self.assertIn("func _montar_imagen(vista: SubViewport, fichero: String) -> bool:", self.pantalla)
        self.assertIn("recurso is Texture2D", self.pantalla)
        self.assertIn("TextureRect.new()", self.pantalla)
        self.assertIn("TextureRect.STRETCH_SCALE", self.pantalla)
        self.assertIn("SubViewport.UPDATE_ONCE", self.pantalla)
        self.assertIn("VideoStreamPlayer.new()", self.pantalla)
        self.assertIn("_montar_nieve", self.pantalla)

    def test_resolucion_de_superficie_es_declarativa(self) -> None:
        self.assertIn('vista.size = declaracion.get("resolucion", RESOLUCION)', self.pantalla)
        self.assertIn("lienzo.size = Vector2(vista.size)", self.pantalla)


if __name__ == "__main__":
    unittest.main()
