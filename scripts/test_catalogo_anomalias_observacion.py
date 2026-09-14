import json
import re
from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CATALOGO = RAIZ / "godot" / "datos" / "anomalias_sueno.json"
UTILERIA = RAIZ / "godot" / "guion" / "sueno_utileria.gd"
ANOMALIA_3D = RAIZ / "godot" / "guion" / "anomalia_sueno_3d.gd"
PRUEBA_GODOT = RAIZ / "godot" / "pruebas" / "pruebas_sueno_reactivo.gd"


class CatalogoAnomaliasObservacionTest(unittest.TestCase):
    def setUp(self):
        self.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        self.utileria = UTILERIA.read_text(encoding="utf-8")
        self.anomalia_3d = ANOMALIA_3D.read_text(encoding="utf-8")
        self.prueba_godot = PRUEBA_GODOT.read_text(encoding="utf-8")

    def test_prescripciones_3d_apuntan_al_catalogo_completo(self):
        ids_catalogo = {entrada["id"] for entrada in self.catalogo}
        ids_utileria = set(
            re.findall(r'"anomalia_id"\s*:\s*"([^"]+)"', self.utileria)
        )
        self.assertEqual(ids_utileria, ids_catalogo)

    def test_interactuable_expone_evento_sin_persistir_por_su_cuenta(self):
        self.assertIn(
            "signal observada(anomalia_id: String, actor: Node)", self.anomalia_3d
        )
        self.assertIn("observada.emit(_catalogo_id, actor)", self.anomalia_3d)
        self.assertIn('datos["anomalia_id"]', self.utileria)
        self.assertNotIn("Partida.", self.anomalia_3d)
        self.assertNotIn("Jornada.", self.anomalia_3d)
        self.assertNotIn("CatalogoAnomalias.", self.anomalia_3d)

    def test_regresion_godot_verifica_identidad_actor_y_repeticion(self):
        self.assertIn("CatalogoAnomalias.ficha(catalogo_id)", self.prueba_godot)
        self.assertIn("anomalia.observada.connect(_capturar_observacion)", self.prueba_godot)
        self.assertIn('_observaciones[0]["id"] == catalogo_id', self.prueba_godot)
        self.assertIn('_observaciones[0]["actor"] == root', self.prueba_godot)
        self.assertIn("_observaciones.size() == 2", self.prueba_godot)


if __name__ == "__main__":
    unittest.main()
