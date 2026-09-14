import json
from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CATALOGO = RAIZ / "godot" / "datos" / "anomalias_sueno.json"
CONTRATO = RAIZ / "godot" / "guion" / "catalogo_anomalias.gd"
UTILERIA = RAIZ / "godot" / "guion" / "sueno_utileria.gd"
PRUEBA_GODOT = RAIZ / "godot" / "pruebas" / "pruebas_catalogo_anomalias.gd"


class CatalogoAnomaliasTest(unittest.TestCase):
    def setUp(self):
        self.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        self.codigo = CONTRATO.read_text(encoding="utf-8")
        self.utileria = UTILERIA.read_text(encoding="utf-8")
        self.prueba_godot = PRUEBA_GODOT.read_text(encoding="utf-8")

    def test_catalogo_declara_ids_estables_y_origen_real(self):
        ids = [entrada["id"] for entrada in self.catalogo]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertGreaterEqual(len(ids), 3)
        for entrada in self.catalogo:
            self.assertEqual(entrada["origen_tipo"], "objeto")
            self.assertIn(entrada["origen_id"], self.utileria)
            representacion = entrada["representacion"]
            self.assertEqual(representacion["modelo"], entrada["origen_id"])
            self.assertEqual(representacion["tipo"], "modelo-procedural")

    def test_catalogo_no_contiene_ubicaciones_soluciones_ni_recompensas(self):
        permitidas = {
            "id",
            "origen_tipo",
            "origen_id",
            "representacion",
            "modo_observacion",
        }
        for entrada in self.catalogo:
            self.assertEqual(set(entrada), permitidas)
        serializado = json.dumps(self.catalogo, ensure_ascii=False).lower()
        for prohibido in ("coordenad", "ubicacion", "solucion", "dinero", "pista", "accion"):
            self.assertNotIn(prohibido, serializado)

    def test_hay_anomalia_visible_por_exploracion(self):
        self.assertTrue(
            any(entrada["modo_observacion"] == "exploracion" for entrada in self.catalogo)
        )

    def test_api_separa_memoria_total_y_vuelta(self):
        self.assertIn('const CLAVE_TOTAL := "anomalias_descubiertas"', self.codigo)
        self.assertIn('const CLAVE_VUELTA := "anomalias_descubiertas_vuelta"', self.codigo)
        self.assertIn("static func registrar(estado: Dictionary, anomalia_id: String)", self.codigo)
        self.assertIn('"ya-reconocida"', self.codigo)
        self.assertIn('"reencontrada"', self.codigo)
        self.assertIn("static func reiniciar_vuelta(estado: Dictionary) -> void", self.codigo)
        self.assertIn("static func progreso(estado: Dictionary) -> Dictionary", self.codigo)

    def test_contrato_no_depende_de_partida_objetivos_ni_plataforma(self):
        for prohibido in ("Partida.", "Jornada.", "SuenoObjetivos", "GodotSteam", "Steam"):
            self.assertNotIn(prohibido, self.codigo)

    def test_hay_regresion_ejecutable_en_godot(self):
        self.assertIn("extends SceneTree", self.prueba_godot)
        self.assertIn("CatalogoAnomalias.registrar", self.prueba_godot)
        self.assertIn("CatalogoAnomalias.reiniciar_vuelta", self.prueba_godot)
        self.assertIn("CatalogoAnomalias.progreso", self.prueba_godot)


if __name__ == "__main__":
    unittest.main()
