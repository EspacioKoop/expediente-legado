"""Pruebas del auditor estático de expedientes SIGA-98 con datos sintéticos."""

import json
import tempfile
import unittest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from auditar_siga98_estados_20261016 import ENTRADA_POR_DEFECTO, auditar, main


def _escribir_expediente_sintetico(directorio):
    """Expediente sintético que ejercita todos los chequeos del auditor."""
    expediente = {
        "casos": [
            {
                "id": "casoSintetico@1",
                "titulo": "CASO_SINTETICO_TITULO",
                "descripcion": "Expediente sintético para probar el auditor.",
                "anioSuceso": 1999,
                "estado": "ABIERTO",
                "confidencial": False,
                "principal": True,
                "registros": [
                    {
                        "id": "memoS@1",
                        "tipo": "MEMORANDO",
                        "folio": "MEMO-S-001",
                        "contenido": "Autorizo el pago sin revisión previa, "
                        "bajo mi responsabilidad.",
                        "fecha": "1999-12-29",
                    },
                    {
                        "id": "actaS@1",
                        "tipo": "ACTA",
                        "folio": "ACTA-S-001",
                        "contenido": "Se revisó la documentación y no se "
                        "encontraron observaciones.",
                        "fecha": "1999-12-30",
                    },
                ],
                "pistas": [
                    {
                        "id": "pistaOkS@1",
                        "registroOrigen": "memoS@1",
                        "descripcion": "Pista sana.",
                        "fraseGatillo": "sin revisión previa",
                    },
                    {
                        "id": "pistaHuerfanaS@1",
                        "registroOrigen": "memoFantasmaS@1",
                        "descripcion": "Apunta a un registro que no existe.",
                    },
                    {
                        "id": "pistaGatilloRotoS@1",
                        "registroOrigen": "actaS@1",
                        "descripcion": "La frase gatillo no está en el acta.",
                        "fraseGatillo": "el peritaje de tinta",
                    },
                    {
                        "id": "pistaSinInstruccionS@1",
                        "registroOrigen": "memoS@1",
                        "descripcion": "Nadie indica cómo descubrirla.",
                    },
                    {
                        "id": "pistaCombinadaS@1",
                        "registroOrigen": "memoS@1",
                        "registroOrigen2": "actaS@1",
                        "descripcion": "Pista combinada sin frase gatillo.",
                    },
                    {
                        "id": "pistaDuplicadaS@1",
                        "registroOrigen": "memoS@1",
                        "descripcion": "Primera copia.",
                        "fraseGatillo": "sin revisión previa",
                    },
                    {
                        "id": "pistaDuplicadaS@1",
                        "registroOrigen": "memoS@1",
                        "descripcion": "Segunda copia.",
                        "fraseGatillo": "sin revisión previa",
                    },
                ],
                "sospechosos": [],
            },
            {
                "id": "casoSintetico@2",
                "titulo": "CASO_SINTETICO_2_TITULO",
                "descripcion": "Caso con estado fuera de catálogo.",
                "anioSuceso": 1993,
                "estado": "EN_REVISION",
                "confidencial": False,
                "principal": False,
                "registros": [],
                "pistas": [],
                "sospechosos": [],
            },
        ],
        "conceptos": [
            {
                "id": "conceptoComiteS@1",
                "nombre": "Comité Sintético",
                "tipo": "ORGANISMO",
                "resumen": "Coordina el expediente; enlaza consigo mismo, el "
                "[[Comité Sintético]], y con el [[Departamento Fantasma]].",
                "pistas": ["pistaOkS@1", "pistaFantasmaS@1"],
            },
        ],
    }
    ruta = Path(directorio) / "casos_sinteticos.json"
    ruta.write_text(
        json.dumps(expediente, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return ruta


def _linea_de(ruta, aguja):
    """Número de línea (1-based) de la primera línea que contiene la aguja."""
    for numero, linea in enumerate(
        ruta.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if aguja in linea:
            return numero
    return None


class AuditoriaSinteticaTest(unittest.TestCase):
    def setUp(self):
        self.directorio = tempfile.TemporaryDirectory()
        self.addCleanup(self.directorio.cleanup)
        self.ruta = _escribir_expediente_sintetico(self.directorio.name)
        self.informe = auditar([self.ruta])

    def _del_tipo(self, tipo):
        return [
            hallazgo
            for hallazgo in self.informe["hallazgos"]
            if hallazgo["tipo"] == tipo
        ]

    def test_pista_sana_no_se_marca(self):
        marcadas = [
            hallazgo["elemento"]
            for hallazgo in self.informe["hallazgos"]
            if hallazgo["elemento"] == "pistaOkS@1"
        ]
        self.assertEqual(marcadas, [])

    def test_referencia_a_registro_ausente(self):
        hallazgos = self._del_tipo("pista_registro_ausente")
        self.assertEqual(len(hallazgos), 1)
        self.assertEqual(hallazgos[0]["elemento"], "pistaHuerfanaS@1")
        self.assertEqual(hallazgos[0]["severidad"], "alta")
        esperada = _linea_de(self.ruta, '"registroOrigen": "memoFantasmaS@1"')
        self.assertEqual(hallazgos[0]["linea"], esperada)

    def test_frase_gatillo_sin_coincidencia_literal(self):
        hallazgos = self._del_tipo("pista_gatillo_no_resuelto")
        self.assertEqual(len(hallazgos), 1)
        self.assertEqual(hallazgos[0]["elemento"], "pistaGatilloRotoS@1")
        self.assertEqual(hallazgos[0]["severidad"], "alta")

    def test_objetivo_sin_instruccion_es_severidad_media(self):
        hallazgos = self._del_tipo("objetivo_sin_instruccion")
        self.assertEqual(
            sorted(hallazgo["elemento"] for hallazgo in hallazgos),
            ["pistaCombinadaS@1", "pistaHuerfanaS@1", "pistaSinInstruccionS@1"],
        )
        self.assertTrue(
            all(hallazgo["severidad"] == "media" for hallazgo in hallazgos)
        )
        combinada = next(
            hallazgo
            for hallazgo in hallazgos
            if hallazgo["elemento"] == "pistaCombinadaS@1"
        )
        self.assertIn("doble origen", combinada["detalle"])

    def test_estado_fuera_de_catalogo_con_linea_exacta(self):
        hallazgos = self._del_tipo("estado_desconocido")
        self.assertEqual(len(hallazgos), 1)
        self.assertEqual(hallazgos[0]["caso"], "casoSintetico@2")
        self.assertEqual(hallazgos[0]["elemento"], "EN_REVISION")
        esperada = _linea_de(self.ruta, '"estado": "EN_REVISION"')
        self.assertEqual(hallazgos[0]["linea"], esperada)

    def test_id_duplicado_en_pistas(self):
        hallazgos = self._del_tipo("id_duplicado")
        self.assertEqual(len(hallazgos), 1)
        self.assertEqual(hallazgos[0]["elemento"], "pistaDuplicadaS@1")
        self.assertIn("pistas", hallazgos[0]["detalle"])

    def test_concepto_que_cita_pista_inexistente(self):
        hallazgos = self._del_tipo("concepto_pista_ausente")
        self.assertEqual(len(hallazgos), 1)
        self.assertEqual(hallazgos[0]["elemento"], "conceptoComiteS@1")
        self.assertIn("pistaFantasmaS@1", hallazgos[0]["detalle"])

    def test_enlace_de_concepto_sin_destino(self):
        hallazgos = self._del_tipo("enlace_sin_destino")
        self.assertEqual(len(hallazgos), 1)
        self.assertIn("Departamento Fantasma", hallazgos[0]["detalle"])

    def test_recuento_y_resumen_del_informe(self):
        fichero = self.informe["ficheros"][0]
        self.assertEqual(fichero["casos"], 2)
        self.assertEqual(fichero["registros"], 2)
        self.assertEqual(fichero["pistas"], 7)
        self.assertEqual(fichero["conceptos"], 1)
        self.assertEqual(self.informe["resumen"]["total"], 9)
        self.assertEqual(
            self.informe["resumen"]["por_severidad"], {"alta": 6, "media": 3}
        )

    def test_informe_determinista(self):
        otra = auditar([self.ruta])
        self.assertEqual(
            json.dumps(self.informe, sort_keys=True),
            json.dumps(otra, sort_keys=True),
        )

    def test_catalogo_de_estados_parametrizable(self):
        informe = auditar([self.ruta], ("ABIERTO", "CERRADO", "EN_REVISION"))
        self.assertEqual(
            [
                hallazgo
                for hallazgo in informe["hallazgos"]
                if hallazgo["tipo"] == "estado_desconocido"
            ],
            [],
        )

    def test_estructura_no_reconocida(self):
        ruta = Path(self.directorio.name) / "sin_casos.json"
        ruta.write_text('{"otra": []}\n', encoding="utf-8")
        informe = auditar([ruta])
        self.assertEqual(
            [hallazgo["tipo"] for hallazgo in informe["hallazgos"]],
            ["estructura_no_reconocida"],
        )


class AuditoriaCliTest(unittest.TestCase):
    def setUp(self):
        self.directorio = tempfile.TemporaryDirectory()
        self.addCleanup(self.directorio.cleanup)
        self.ruta = _escribir_expediente_sintetico(self.directorio.name)

    def test_informe_a_fichero_con_codigo_cero(self):
        destino = Path(self.directorio.name) / "informe.json"
        self.assertEqual(
            main(["--entrada", str(self.ruta), "--salida", str(destino)]), 0
        )
        informe = json.loads(destino.read_text(encoding="utf-8"))
        self.assertEqual(informe["resumen"]["total"], len(informe["hallazgos"]))

    def test_estricto_devuelve_1_con_hallazgos(self):
        self.assertEqual(main(["--entrada", str(self.ruta), "--estricto"]), 1)

    def test_entrada_inexistente_devuelve_2(self):
        ausente = Path(self.directorio.name) / "ausente.json"
        self.assertEqual(main(["--entrada", str(ausente)]), 2)

    def test_entrada_por_defecto_existe_en_el_repositorio(self):
        self.assertTrue(ENTRADA_POR_DEFECTO.is_file())


if __name__ == "__main__":
    unittest.main()
