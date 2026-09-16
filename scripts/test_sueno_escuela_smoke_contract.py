from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SMOKE = ROOT / "godot" / "guion" / "sueno_escuela_smoke.gd"


class SuenoEscuelaSmokeContractTest(unittest.TestCase):
    def test_smoke_importa_logica_y_audio_escolar(self):
        texto = SMOKE.read_text(encoding="utf-8")
        self.assertIn("class_name SuenoEscuelaSmoke", texto)
        self.assertIn("SuenoEscuela.es_forma(SuenoEscuela.FORMA)", texto)
        self.assertIn("SuenoEscuelaAudio.timbre()", texto)
        self.assertIn("SuenoEscuelaAudio.voces_vacias()", texto)


if __name__ == "__main__":
    unittest.main()
