from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "golf.gd"
PARTIDA = ROOT / "godot" / "guion" / "golf_partida_app.gd"


class GolfTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")
        self.partida = PARTIDA.read_text(encoding="utf-8")

    def test_nucleo_standalone_de_tres_hoyos(self):
        self.assertIn("class_name Golf", self.source)
        self.assertIn("extends RefCounted", self.source)
        self.assertIn("const HOYOS := 3", self.source)
        self.assertIn("static func nueva(jugadores: Array)", self.source)
        self.assertIn("static func golpear(", self.source)
        self.assertIn("static func terminar_hoyo(", self.source)
        self.assertIn("static func resultado(estado: Dictionary)", self.source)
        self.assertNotIn("extends Node", self.source)
        codigo = "\n".join(
            linea for linea in self.source.splitlines()
            if not linea.lstrip().startswith("#")
        )
        self.assertNotIn("partida.", codigo.lower())

    def test_turno_no_puede_quedar_bloqueado(self):
        self.assertIn("const MAX_GOLPES_POR_HOYO := 12", self.source)
        self.assertIn(
            'if int(estado["golpes_hoyo"][jugador]) >= MAX_GOLPES_POR_HOYO:',
            self.source,
        )
        self.assertIn("return terminar_hoyo(estado, jugador)", self.source)
        self.assertIn("_avanzar_turno(estado)", self.source)

    def test_resultado_usa_menor_numero_de_golpes(self):
        self.assertIn('"golpes": int(totales[jugador])', self.source)
        self.assertIn('return int(a["golpes"]) < int(b["golpes"])', self.source)
        self.assertIn('ganador = String(ranking[0]["jugador"])', self.source)
        self.assertIn('ganador = "empate"', self.source)

    def test_partida_resuelve_tres_perfiles_de_companero_sin_rng(self):
        self.assertIn(
            'const LANZADORES := ["jugador", "prudente", "agresiva", "absurda"]',
            self.partida,
        )
        for perfil in ("prudente", "agresiva", "absurda"):
            self.assertIn(f'"{perfil}": [', self.partida)
        self.assertIn("Golf.nueva(LANZADORES)", self.partida)
        self.assertIn("func _resolver_turnos_companeros(", self.partida)
        self.assertIn("Golf.golpear(estado, actual)", self.partida)
        self.assertIn("Golf.terminar_hoyo(estado, actual)", self.partida)
        for prohibido in ("RandomNumberGenerator", "randf(", "randi(", "Partida.", "RankingGolf"):
            self.assertNotIn(prohibido, self.partida)

    def test_abandono_no_marca_partida_completa(self):
        self.assertIn('estado["abandonada"] = true', self.source)
        self.assertIn("var completa: bool = (", self.source)
        self.assertIn('bool(estado.get("terminada", false))', self.source)
        self.assertIn('not bool(estado.get("abandonada", false))', self.source)


if __name__ == "__main__":
    unittest.main()
