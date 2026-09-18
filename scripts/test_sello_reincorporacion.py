from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = json.loads((ROOT / "godot/datos/sellos.json").read_text(encoding="utf-8"))
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
JORNADA = (ROOT / "godot/guion/jornada.gd").read_text(encoding="utf-8")


class SelloReincorporacionTests(unittest.TestCase):
    def test_catalogo_declara_reincorporacion(self):
        por_id = {entrada["id"]: entrada for entrada in CATALOGO}
        self.assertIn("reincorporacion-administrativa", por_id)
        sello = por_id["reincorporacion-administrativa"]
        self.assertEqual(sello["origen"], "reasignacion")
        self.assertTrue(sello["disponible"])

    def test_emisor_deriva_del_contador_de_vuelta_existente(self):
        self.assertIn('const SELLO_REINCORPORACION := "reincorporacion-administrativa"', DIA)
        self.assertIn('int(jornada.get("vuelta", 1)) <= 1', DIA)
        self.assertIn("Sellos.registrar_sello(partida.estado, SELLO_REINCORPORACION)", DIA)
        self.assertIn('"vuelta": vuelta', JORNADA)

    def test_la_entrada_de_vuelta_dispara_el_emisor(self):
        abrir = DIA.split("func _abrir_vuelta() -> void:", 1)[1].split(
            "func _registrar_reincorporacion", 1
        )[0]
        self.assertIn("_registrar_reincorporacion()", abrir)
        self.assertLess(
            abrir.index("_registrar_reincorporacion()"),
            abrir.index("_entrada = load("),
        )

    def test_no_crea_estado_paralelo_ni_efectos_de_gameplay(self):
        bloque = DIA.split("func _registrar_reincorporacion", 1)[1].split(
            "## Al acabar la entrada", 1
        )[0]
        for prohibido in (
            "reincorporaciones",
            'jornada["dinero"] =',
            'jornada["acciones"] =',
            'partida.estado["vida"] =',
            'partida.estado["pistas_descubiertas"] =',
            "_guardar_o_avisar(",
            "Prometeo.reiniciar_vuelta",
            "Jornada.reiniciar_vuelta",
        ):
            self.assertNotIn(prohibido, bloque)


if __name__ == "__main__":
    unittest.main()
