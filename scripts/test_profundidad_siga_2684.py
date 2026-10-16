"""Regresión de las tres investigaciones ampliadas SIGA-98 (#2684).

El código no evalúa culpables ni narra acontecimientos nuevos. Verifica que el
catálogo real permite recorrer cada conflicto mediante folios y relaciones
legibles, también bajo el locale en.
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
NUEVOS = {
    "caso5@5": {
        "registros": {"resguardo1978@5", "cotejo2007@5"},
        "pistas": {"pista65@5", "pista66@5", "pista67@5", "pista68@5", "pista69@5"},
        "relaciones": {
            frozenset(("resguardo1978@5", "memo5@5")),
            frozenset(("cotejo2007@5", "empleado5@5")),
            frozenset(("resguardo1978@5", "acta5@5")),
        },
    },
    "caso8@8": {
        "registros": {"controlTerminal8@8", "mantenimientoVentanas8@8"},
        "pistas": {"pista70@8", "pista71@8", "pista72@8", "pista73@8", "pista74@8"},
        "relaciones": {
            frozenset(("controlTerminal8@8", "empleado427@8")),
            frozenset(("mantenimientoVentanas8@8", "actaB@8")),
            frozenset(("controlTerminal8@8", "actaA@8")),
        },
    },
    "caso11@11": {
        "registros": {"cubiertaArchivo11@11", "revisionAsiento11@11"},
        "pistas": {"pista75@11", "pista76@11", "pista77@11", "pista78@11", "pista79@11"},
        "relaciones": {
            frozenset(("cubiertaArchivo11@11", "archivo11@11")),
            frozenset(("cubiertaArchivo11@11", "imprenta11@11")),
            frozenset(("revisionAsiento11@11", "acta11@11")),
        },
    },
}


class ProfundidadSiga2684Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogos = {
            idioma: {
                c["id"]: c
                for c in json.loads(ruta.read_text(encoding="utf-8"))["casos"]
            }
            for idioma, ruta in RUTAS.items()
        }

    def test_conserva_once_casos_y_sesenta_folios(self):
        for idioma, catalogo in self.catalogos.items():
            with self.subTest(locale=idioma):
                self.assertEqual(len(catalogo), 11)
                self.assertEqual(sum(len(c["registros"]) for c in catalogo.values()), 60)
                self.assertEqual(sum(len(c["pistas"]) for c in catalogo.values()), 79)

    def test_los_tres_casos_contienen_dos_nuevos_folios(self):
        for idioma, catalogo in self.catalogos.items():
            for id_caso, plan in NUEVOS.items():
                with self.subTest(locale=idioma, caso=id_caso):
                    c = catalogo[id_caso]
                    ids = [r["id"] for r in c["registros"]]
                    folios = [r["folio"] for r in c["registros"]]
                    self.assertEqual(len(ids), len(set(ids)))
                    self.assertEqual(len(folios), len(set(folios)))
                    self.assertTrue(plan["registros"] <= set(ids))
                    for r in c["registros"]:
                        if r["id"] in plan["registros"]:
                            self.assertEqual(date.fromisoformat(r["fecha"]).isoformat(), r["fecha"])
                            self.assertGreater(len(r["contenido"]), 120)
                            self.assertTrue(r["tipo"])

    def test_pistas_nuevas_disparan_desde_texto_y_relacionan_pares_unicos(self):
        for idioma, catalogo in self.catalogos.items():
            for id_caso, plan in NUEVOS.items():
                with self.subTest(locale=idioma, caso=id_caso):
                    c = catalogo[id_caso]
                    docs = {r["id"]: r for r in c["registros"]}
                    ids = [p["id"] for p in c["pistas"]]
                    self.assertEqual(len(ids), len(set(ids)))
                    self.assertTrue(plan["pistas"] <= set(ids))
                    parejas = set()
                    parejas_nuevas = set()
                    frases_nuevas = 0
                    for p in c["pistas"]:
                        self.assertIn(p["registroOrigen"], docs)
                        frase = p.get("fraseGatillo")
                        if frase:
                            self.assertIn(
                                frase, docs[p["registroOrigen"]]["contenido"],
                                f"{idioma}/{p['id']}: frase no encontrada",
                            )
                            if p["id"] in plan["pistas"]:
                                frases_nuevas += 1
                        segundo = p.get("registroOrigen2")
                        if segundo:
                            self.assertIn(segundo, docs)
                            self.assertNotEqual(segundo, p["registroOrigen"])
                            pareja = frozenset((p["registroOrigen"], segundo))
                            self.assertNotIn(pareja, parejas)
                            parejas.add(pareja)
                            if p["id"] in plan["pistas"]:
                                parejas_nuevas.add(pareja)
                    self.assertEqual(frases_nuevas, 2)
                    self.assertEqual(parejas_nuevas, plan["relaciones"])

    def test_espejo_ingles_conserva_folios_fechas_y_claves(self):
        for caso_id, plan in NUEVOS.items():
            es, en = (self.catalogos[idioma][caso_id] for idioma in ("es", "en"))
            for campo in ("id", "anioSuceso", "estado", "confidencial", "principal"):
                self.assertEqual(es[campo], en[campo])
            self.assertEqual(len(es["registros"]), len(en["registros"]))
            self.assertEqual(len(es["pistas"]), len(en["pistas"]))
            for doc_es, doc_en in zip(es["registros"], en["registros"], strict=True):
                for campo in ("id", "tipo", "folio", "fecha"):
                    self.assertEqual(doc_es[campo], doc_en[campo])
                if doc_es["id"] in plan["registros"]:
                    self.assertNotEqual(doc_es["contenido"], doc_en["contenido"])
            for p_es, p_en in zip(es["pistas"], en["pistas"], strict=True):
                for campo in ("id", "registroOrigen", "registroOrigen2"):
                    self.assertEqual(p_es.get(campo), p_en.get(campo))
                if p_es["id"] in plan["pistas"]:
                    self.assertNotEqual(p_es["descripcion"], p_en["descripcion"])
                    if "fraseGatillo" in p_es:
                        self.assertNotEqual(p_es["fraseGatillo"], p_en["fraseGatillo"])

    def test_nuevos_documentos_no_afirman_culpabilidad_o_final_automatico(self):
        prohibidas_es = ("culpable de", "queda demostrado que fue", "única explicación")
        prohibidas_en = ("is guilty of", "it proves that", "only possible explanation")
        for idioma, catalogo in self.catalogos.items():
            prohibidas = prohibidas_es if idioma == "es" else prohibidas_en
            for caso_id, plan in NUEVOS.items():
                c = catalogo[caso_id]
                nuevo_texto = [
                    r["contenido"]
                    for r in c["registros"]
                    if r["id"] in plan["registros"]
                ]
                nuevo_texto.extend(
                    p["descripcion"]
                    for p in c["pistas"]
                    if p["id"] in plan["pistas"]
                )
                for texto in nuevo_texto:
                    for afirmacion in prohibidas:
                        self.assertNotIn(afirmacion, texto.lower())

    def test_diez_enlaces_de_pistas_se_pueden_consultar_en_el_corcho(self):
        enlaces = {
            "conceptoBienestar@6": {"pista58@2", "pista59@2"},
            "conceptoPiso13@6": {"pista63@3"},
            "conceptoMontalvo@6": {"pista62@3", "pista64@3"},
            "conceptoMemoRepetido@6": {"pista67@5", "pista68@5"},
            "conceptoArchivoMuerto@6": {"pista69@5"},
            "concepto427@8": {"pista72@8", "pista73@8"},
        }
        for idioma, ruta in RUTAS.items():
            datos = json.loads(ruta.read_text(encoding="utf-8"))
            conceptos = {c["id"]: c for c in datos["conceptos"]}
            todas_las_pistas = {
                pista["id"] for caso in datos["casos"] for pista in caso["pistas"]
            }
            with self.subTest(locale=idioma):
                self.assertEqual(len(conceptos), 16)
                for concepto_id, pistas in enlaces.items():
                    self.assertTrue(pistas <= set(conceptos[concepto_id]["pistas"]))
                    self.assertTrue(pistas <= todas_las_pistas)

    def test_el_caso_8_aporta_hora_verificable_a_las_tres_actas(self):
        for idioma, catalogo in self.catalogos.items():
            c = catalogo["caso8@8"]
            firmas = [
                r["contenido"]
                for r in c["registros"]
                if r["id"] in ("actaA@8", "actaB@8", "actaC@8")
            ]
            with self.subTest(locale=idioma):
                self.assertEqual(len(firmas), 3)
                self.assertTrue(all("14:00" in texto for texto in firmas))


if __name__ == "__main__":
    unittest.main()
