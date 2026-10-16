"""Regresión de profundidad documental SIGA-98 para los casos 2 y 3 (#2666).

Se comprueban contratos que el visor real consume: texto literal pulsable,
pares de folios sin duplicados, persistencia por IDs estables y espejo ES/EN.
No sustituye el playtest humano de #431.
"""

import json
import unittest
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUTAS = {
    "es": ROOT / "godot" / "datos" / "casos.json",
    "en": ROOT / "godot" / "datos" / "casos.en.json",
}
AMPLIACIONES = {
    "caso2@2": {
        "folios": {"dictamenMedico2@2", "recepcionSilla2@2"},
        "pistas": {"pista55@2", "pista56@2", "pista57@2", "pista58@2", "pista59@2"},
        "pares": {
            frozenset(("dictamenMedico2@2", "recepcionSilla2@2")),
            frozenset(("circular2@2", "recepcionSilla2@2")),
            frozenset(("recepcionSilla2@2", "empleado2@2")),
        },
        "originales": {
            "oficio2@2", "circular2@2", "empleado2@2", "oficioReestructura2@2"
        },
    },
    "caso3@3": {
        "folios": {"controlAcceso3@3", "inventarioRotulos3@3"},
        "pistas": {"pista60@3", "pista61@3", "pista62@3", "pista63@3", "pista64@3"},
        "pares": {
            frozenset(("memo3@3", "controlAcceso3@3")),
            frozenset(("oficio3@3", "inventarioRotulos3@3")),
            frozenset(("controlAcceso3@3", "inventarioRotulos3@3")),
        },
        "originales": {"memo3@3", "oficio3@3", "acta3@3", "empleado3@3"},
    },
}


class ProfundidadSiga2666Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogos = {
            idioma: {
                caso["id"]: caso
                for caso in json.loads(ruta.read_text(encoding="utf-8"))["casos"]
            }
            for idioma, ruta in RUTAS.items()
        }

    def test_dos_expedientes_ampliados_sin_reemplazar_folios_anteriores(self):
        for idioma, catalogo in self.catalogos.items():
            for caso_id, contrato in AMPLIACIONES.items():
                with self.subTest(idioma=idioma, caso=caso_id):
                    caso = catalogo[caso_id]
                    folios = {r["id"] for r in caso["registros"]}
                    pistas = {p["id"] for p in caso["pistas"]}
                    self.assertEqual(len(folios), len(caso["registros"]))
                    self.assertEqual(len(pistas), len(caso["pistas"]))
                    self.assertTrue(
                        contrato["originales"] | contrato["folios"] <= folios
                    )
                    self.assertTrue(contrato["pistas"] <= pistas)
                    self.assertEqual(len(caso["registros"]), 6)

    def test_folios_tienen_fechas_validas_y_folio_visible_unico(self):
        for idioma, catalogo in self.catalogos.items():
            for caso_id, contrato in AMPLIACIONES.items():
                caso = catalogo[caso_id]
                documentos = {r["id"]: r for r in caso["registros"]}
                self.assertEqual(
                    len({r["folio"] for r in caso["registros"]}),
                    len(caso["registros"]),
                )
                for doc_id in contrato["folios"]:
                    with self.subTest(idioma=idioma, documento=doc_id):
                        doc = documentos[doc_id]
                        self.assertTrue(doc["tipo"])
                        self.assertTrue(doc["folio"])
                        self.assertGreater(len(doc["contenido"]), 100)
                        self.assertEqual(
                            date.fromisoformat(doc["fecha"]).isoformat(), doc["fecha"]
                        )

    def test_frases_se_pueden_pulsar_y_relaciones_se_pueden_comparar(self):
        for idioma, catalogo in self.catalogos.items():
            for caso_id, contrato in AMPLIACIONES.items():
                caso = catalogo[caso_id]
                registros = {r["id"]: r for r in caso["registros"]}
                parejas = set()
                nuevas_relaciones = set()
                pistas_nuevas_de_frase = 0
                for pista in caso["pistas"]:
                    self.assertIn(pista["registroOrigen"], registros)
                    origen2 = pista.get("registroOrigen2")
                    if origen2:
                        self.assertIn(origen2, registros)
                        self.assertNotEqual(origen2, pista["registroOrigen"])
                        pareja = frozenset((origen2, pista["registroOrigen"]))
                        self.assertNotIn(pareja, parejas)
                        parejas.add(pareja)
                        if pista["id"] in contrato["pistas"]:
                            nuevas_relaciones.add(pareja)
                    if pista.get("fraseGatillo"):
                        self.assertIn(
                            pista["fraseGatillo"],
                            registros[pista["registroOrigen"]]["contenido"],
                            f"{idioma}: la pista {pista['id']} no es pulsable",
                        )
                        if pista["id"] in contrato["pistas"]:
                            pistas_nuevas_de_frase += 1
                with self.subTest(idioma=idioma, caso=caso_id):
                    self.assertEqual(nuevas_relaciones, contrato["pares"])
                    self.assertEqual(pistas_nuevas_de_frase, 2)

    def test_espejo_ingles_conserva_reglas_e_ids_y_traduce_pistas(self):
        for caso_id, contrato in AMPLIACIONES.items():
            es, en = (self.catalogos[lang][caso_id] for lang in ("es", "en"))
            for campo in ("id", "anioSuceso", "estado", "principal", "confidencial"):
                self.assertEqual(es[campo], en[campo])
            self.assertEqual(len(es["registros"]), len(en["registros"]))
            self.assertEqual(len(es["pistas"]), len(en["pistas"]))
            for doc_es, doc_en in zip(es["registros"], en["registros"], strict=True):
                for campo in ("id", "tipo", "folio", "fecha"):
                    self.assertEqual(doc_es[campo], doc_en[campo])
                if doc_es["id"] in contrato["folios"]:
                    self.assertNotEqual(doc_es["contenido"], doc_en["contenido"])
            for pista_es, pista_en in zip(es["pistas"], en["pistas"], strict=True):
                for campo in ("id", "registroOrigen", "registroOrigen2"):
                    self.assertEqual(pista_es.get(campo), pista_en.get(campo))
                if pista_es["id"] in contrato["pistas"]:
                    self.assertNotEqual(pista_es["descripcion"], pista_en["descripcion"])
                    if "fraseGatillo" in pista_es:
                        self.assertNotEqual(
                            pista_es["fraseGatillo"], pista_en["fraseGatillo"]
                        )


if __name__ == "__main__":
    unittest.main()
