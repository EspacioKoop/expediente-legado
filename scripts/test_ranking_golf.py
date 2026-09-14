from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
LOCAL_SOURCE = ROOT / "godot" / "guion" / "ranking_golf.gd"
ONLINE_SOURCE = ROOT / "godot" / "guion" / "ranking_golf_online.gd"


class RankingGolfTest(unittest.TestCase):
    def setUp(self):
        self.local = LOCAL_SOURCE.read_text(encoding="utf-8")
        self.online = ONLINE_SOURCE.read_text(encoding="utf-8")

    def test_ranking_offline_persistente_y_acotado(self):
        self.assertIn('const RUTA_LOCAL := "user://ranking_golf.json"', self.local)
        self.assertIn("const LIMITE_LOCAL := 50", self.local)
        self.assertIn("static func cargar_local(", self.local)
        self.assertIn("static func guardar_local(", self.local)
        self.assertIn("FileAccess.open", self.local)
        self.assertIn("JSON.stringify", self.local)

    def test_solo_entran_partidas_completas(self):
        self.assertIn('if not resultado_partida.get("completa", false):', self.local)
        self.assertIn("GOLPES_MINIMOS := 3", self.local)
        self.assertIn("Golf.HOYOS * Golf.MAX_GOLPES_POR_HOYO", self.local)
        self.assertIn('if golpes < GOLPES_MINIMOS or golpes > GOLPES_MAXIMOS:', self.local)

    def test_orden_es_menor_golpes_primero(self):
        self.assertIn('return int(a["golpes"]) < int(b["golpes"])', self.local)
        self.assertIn('return int(a["fecha_unix"]) < int(b["fecha_unix"])', self.local)

    def test_online_es_opcional_y_no_guarda_credenciales(self):
        self.assertIn("class_name RankingGolfOnline", self.online)
        self.assertIn("extends Node", self.online)
        self.assertIn("HTTPRequest.new()", self.online)
        self.assertIn('const RUTA_API := "/api/golf/ranking"', self.online)
        self.assertIn("HTTPClient.METHOD_POST", self.online)
        self.assertIn('endpoint_base := ""', self.online)
        self.assertNotIn("token", self.online.lower())
        self.assertNotIn("password", self.online.lower())

    def test_fallo_online_es_explicito(self):
        self.assertIn('error_online.emit("ranking_online_no_configurado")', self.online)
        self.assertIn('error_online.emit("ranking_online_transporte_fallido")', self.online)
        self.assertIn('error_online.emit("ranking_online_respuesta_invalida")', self.online)


if __name__ == "__main__":
    unittest.main()
