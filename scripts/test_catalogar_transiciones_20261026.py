"""Tests offline del catálogo de transiciones narrativas (#2738)."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).with_name("catalogar_transiciones_20261026.py")
spec = importlib.util.spec_from_file_location("catalogar_transiciones", MODULE)
catalogar = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalogar)

CASOS = {
    "casos": [
        {
            "id": "caso@1",
            "titulo": "CASO_1_TITULO",
            "estado": "ABIERTO",
            "principal": True,
            "registros": [{"id": "memo1@1", "contenido": "sin revisión previa"}],
            "pistas": [
                {
                    "id": "pista1@1",
                    "registroOrigen": "memo1@1",
                    "fraseGatillo": "sin revisión previa",
                },
                {
                    "id": "pista2@1",
                    "registroOrigen": "memo1@1",
                    "registroOrigen2": "factura1@1",
                    "fraseGatillo": "consultoría",
                },
            ],
            "sospechosos": [{"id": "sospechoso1@1"}],
        }
    ],
    "conceptos": [
        {"id": "conceptoA@1", "nombre": "Comité", "resumen": "Ordenó [[Carcosa]]"},
        {"id": "conceptoB@1", "nombre": "Carcosa", "resumen": "Vigila [[Nadie]]"},
    ],
}

PARTIDA = '"pistas_descubiertas": [],\n"veredictos": {},\n'
CONSUMIDOR = '"pistas_descubiertas"'


class CatalogoTransicionesTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        guion = self.root / "godot" / "guion"
        guion.mkdir(parents=True)
        (self.root / "godot" / "datos").mkdir(parents=True)

    def _escribir_base(self, casos=CASOS, partida=PARTIDA, consumidor=CONSUMIDOR):
        datos = self.root / "godot" / "datos" / "casos.json"
        datos.write_text(json.dumps(casos, ensure_ascii=False), encoding="utf-8")
        (self.root / "godot" / "guion" / "partida.gd").write_text(partida, encoding="utf-8")
        visor = self.root / "godot" / "guion" / "visor_expediente.gd"
        visor.write_text("var x = estado[\"pistas_descubiertas\"]\n", encoding="utf-8")
        (self.root / "godot" / "guion" / "acusacion.gd").write_text(
            'estado.get("veredictos", {})\n', encoding="utf-8"
        )
        (self.root / "godot" / "guion" / "sellos.gd").write_text(
            "const CLAVE_ESTADO := \"sellos_obtenidos\"\n", encoding="utf-8"
        )
        (self.root / "godot" / "guion" / "catalogo_anomalias.gd").write_text(
            'const CLAVE_TOTAL := "anomalias_descubiertas"\n', encoding="utf-8"
        )
        (self.root / "godot" / "guion" / "reconstruccion_expediente.gd").write_text(
            'estado.get("reconstrucciones", {})\n', encoding="utf-8"
        )
        (self.root / "godot" / "guion" / "pronosticos_auditoria.gd").write_text(
            'estado.get("pronosticos", {})\n', encoding="utf-8"
        )
        (self.root / "godot" / "guion" / "careo_contexto_app.gd").write_text(
            'estado.get("pistas_descubiertas", [])\n', encoding="utf-8"
        )
        return catalogar.catalogar(self.root)

    def test_catalogo_completo_y_determinista(self):
        resultado = self._escribir_base()
        self.assertEqual(resultado["totales"]["casos"], 1)
        self.assertEqual(resultado["totales"]["pistas"], 2)
        self.assertEqual(resultado["totales"]["pistas_doble_origen"], 1)
        caso = resultado["casos"][0]
        self.assertEqual(caso["pistas"][0]["gatillo"], "sin revisión previa")
        self.assertEqual(caso["pistas"][1]["origenes"], ["memo1@1", "factura1@1"])
        otra_vez = self._escribir_base()
        self.assertEqual(resultado, otra_vez)

    def test_enlaces_de_conceptos_con_destino(self):
        resultado = self._escribir_base()
        conceptos = {c["concepto"]: c for c in resultado["conceptos"]}
        self.assertEqual(conceptos["conceptoA@1"]["enlaces"], ["Carcosa"])
        self.assertEqual(conceptos["conceptoB@1"]["enlaces_sin_destino"], ["Nadie"])

    def test_variables_apuntan_a_escena_y_linea_reales(self):
        resultado = self._escribir_base()
        escenas = resultado["variables"]["pistas_descubiertas"]["escenas"]
        self.assertTrue(escenas)
        for escena in escenas:
            ruta = self.root / "godot" / escena["escena"]
            self.assertTrue(ruta.is_file(), escena["escena"])
            lineas = ruta.read_text(encoding="utf-8").splitlines()
            self.assertIn("pistas_descubiertas", lineas[escena["linea"] - 1])

    def test_variable_sin_esquema_de_partida_es_inconsistencia(self):
        casos = json.loads(json.dumps(CASOS))
        self._escribir_base()
        partida = self.root / "godot" / "guion" / "partida.gd"
        partida.write_text('"veredictos": {},\n', encoding="utf-8")
        resultado = catalogar.catalogar(self.root)
        self.assertIn(
            "pistas_descubiertas",
            resultado["consistencia"]["variables_sin_esquema"],
        )

    def test_variable_sin_consumidor_es_inconsistencia(self):
        self._escribir_base()
        visor = self.root / "godot" / "guion" / "visor_expediente.gd"
        visor.write_text("nada\n", encoding="utf-8")
        careo = self.root / "godot" / "guion" / "careo_contexto_app.gd"
        careo.write_text("nada\n", encoding="utf-8")
        resultado = catalogar.catalogar(self.root)
        self.assertIn(
            "pistas_descubiertas",
            resultado["consistencia"]["variables_sin_consumidor"],
        )

    def test_raiz_sin_datos_es_error(self):
        with self.assertRaises(ValueError):
            catalogar.catalogar(self.root)


if __name__ == "__main__":
    unittest.main()
