from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = json.loads((ROOT / "godot/datos/sellos.json").read_text(encoding="utf-8"))
JORNADA = (ROOT / "godot/guion/jornada.gd").read_text(encoding="utf-8")
ACUSACION = (ROOT / "godot/guion/acusacion.gd").read_text(encoding="utf-8")
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
ASCENSOR = (ROOT / "godot/guion/dia_ascensor_app.gd").read_text(encoding="utf-8")


class SelloFirmaSinPrisaTests(unittest.TestCase):
    def test_catalogo_separa_firma_de_ronda_de_cierre(self):
        por_id = {entrada["id"]: entrada for entrada in CATALOGO}
        self.assertIn("firma-sin-prisa", por_id)
        self.assertIn("planta-en-orden", por_id)
        self.assertEqual(por_id["firma-sin-prisa"]["origen"], "cierre-expedientes")
        self.assertEqual(por_id["planta-en-orden"]["origen"], "ronda-cierre")

    def test_acusacion_deja_senal_diaria_y_despertar_la_limpia(self):
        self.assertIn('"acusaciones_precipitadas_hoy": 0', JORNADA)
        self.assertIn('jornada["acusaciones_precipitadas_hoy"] = (', ACUSACION)
        self.assertIn('int(jornada.get("acusaciones_precipitadas_hoy", 0)) + 1', ACUSACION)
        self.assertGreaterEqual(
            JORNADA.count('jornada["acusaciones_precipitadas_hoy"] = 0'),
            1,
        )

    def test_las_dos_salidas_de_oficina_emiten_antes_del_guardado(self):
        self.assertIn("_registrar_firma_sin_prisa()\n\t\t\tvar paga := Jornada.fichar_salida", DIA)
        self.assertIn("_registrar_firma_sin_prisa()\n\tvar paga := Jornada.fichar_salida", ASCENSOR)
        self.assertIn('const SELLO_FIRMA_SIN_PRISA := "firma-sin-prisa"', DIA)
        self.assertIn('int(jornada.get("cerrados_hoy", 0)) <= 0', DIA)
        self.assertIn('int(jornada.get("acusaciones_precipitadas_hoy", 0)) != 0', DIA)

    def test_emisor_es_cosmetico_y_no_fuerza_guardado(self):
        bloque = DIA.split("func _registrar_firma_sin_prisa", 1)[1].split(
            "## Hook de presentación", 1
        )[0]
        self.assertIn("Sellos.registrar_sello", bloque)
        for prohibido in (
            'jornada["dinero"] =',
            'jornada["acciones"] =',
            'partida.estado["vida"] =',
            'partida.estado["veredictos"] =',
            "_guardar_o_avisar(",
            "partida.guardar(",
        ):
            self.assertNotIn(prohibido, bloque)


if __name__ == "__main__":
    unittest.main()
