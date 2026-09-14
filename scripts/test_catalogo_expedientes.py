import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CASOS = ROOT / "godot" / "datos" / "casos.json"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class CatalogoExpedientesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogo = json.loads(CASOS.read_text(encoding="utf-8"))
        cls.casos = cls.catalogo.get("casos", [])

    def test_catalogo_tiene_casos(self):
        self.assertIsInstance(self.casos, list)
        self.assertGreater(len(self.casos), 0)

    def test_ids_de_caso_son_unicos_y_campos_obligatorios_existen(self):
        ids = []
        obligatorios = {
            "id",
            "titulo",
            "descripcion",
            "anioSuceso",
            "estado",
            "confidencial",
            "principal",
            "registros",
            "pistas",
            "sospechosos",
        }
        for caso in self.casos:
            faltan = obligatorios.difference(caso)
            self.assertFalse(faltan, f"{caso.get('id', '<sin id>')}: faltan {sorted(faltan)}")
            self.assertIsInstance(caso["anioSuceso"], int, caso["id"])
            self.assertIsInstance(caso["confidencial"], bool, caso["id"])
            self.assertIsInstance(caso["principal"], bool, caso["id"])
            self.assertTrue(str(caso["titulo"]).strip(), caso["id"])
            self.assertTrue(str(caso["descripcion"]).strip(), caso["id"])
            self.assertTrue(str(caso["estado"]).strip(), caso["id"])
            ids.append(caso["id"])
        self.assertEqual(len(ids), len(set(ids)), "IDs de caso duplicados")

    def test_registros_tienen_ids_y_folios_unicos_dentro_del_caso(self):
        obligatorios = {"id", "tipo", "folio", "contenido", "fecha"}
        for caso in self.casos:
            ids = []
            folios = []
            self.assertGreater(len(caso["registros"]), 0, caso["id"])
            for registro in caso["registros"]:
                faltan = obligatorios.difference(registro)
                self.assertFalse(
                    faltan,
                    f"{caso['id']}/{registro.get('id', '<sin id>')}: faltan {sorted(faltan)}",
                )
                for campo in obligatorios:
                    self.assertTrue(str(registro[campo]).strip(), f"{caso['id']}/{registro['id']}:{campo}")
                ids.append(registro["id"])
                folios.append(registro["folio"])
            self.assertEqual(len(ids), len(set(ids)), f"{caso['id']}: IDs de registro duplicados")
            self.assertEqual(len(folios), len(set(folios)), f"{caso['id']}: folios duplicados")

    def test_pistas_referencian_documentos_del_mismo_caso(self):
        obligatorios = {"id", "registroOrigen", "descripcion"}
        for caso in self.casos:
            registros = {registro["id"] for registro in caso["registros"]}
            ids = []
            self.assertGreater(len(caso["pistas"]), 0, caso["id"])
            for pista in caso["pistas"]:
                faltan = obligatorios.difference(pista)
                self.assertFalse(
                    faltan,
                    f"{caso['id']}/{pista.get('id', '<sin id>')}: faltan {sorted(faltan)}",
                )
                self.assertIn(pista["registroOrigen"], registros, f"{caso['id']}/{pista['id']}")
                segundo = pista.get("registroOrigen2")
                if segundo is not None:
                    self.assertIn(segundo, registros, f"{caso['id']}/{pista['id']}")
                    self.assertNotEqual(segundo, pista["registroOrigen"], f"{caso['id']}/{pista['id']}")
                ids.append(pista["id"])
            self.assertEqual(len(ids), len(set(ids)), f"{caso['id']}: IDs de pista duplicados")

    def test_frases_gatillo_aparecen_literalmente_en_su_documento(self):
        for caso in self.casos:
            registros = {registro["id"]: registro for registro in caso["registros"]}
            for pista in caso["pistas"]:
                frase = pista.get("fraseGatillo")
                if frase is None:
                    continue
                self.assertTrue(str(frase), f"{caso['id']}/{pista['id']}: fraseGatillo vacía")
                contenido = registros[pista["registroOrigen"]]["contenido"]
                self.assertIn(
                    frase,
                    contenido,
                    f"{caso['id']}/{pista['id']}: la frase gatillo no aparece literalmente",
                )

    def test_sospechosos_tienen_desenlace_y_ids_unicos(self):
        obligatorios = {"id", "nombre", "descripcion", "desenlace"}
        for caso in self.casos:
            ids = []
            self.assertGreater(len(caso["sospechosos"]), 0, caso["id"])
            for sospechoso in caso["sospechosos"]:
                faltan = obligatorios.difference(sospechoso)
                self.assertFalse(
                    faltan,
                    f"{caso['id']}/{sospechoso.get('id', '<sin id>')}: faltan {sorted(faltan)}",
                )
                for campo in obligatorios:
                    self.assertTrue(
                        str(sospechoso[campo]).strip(),
                        f"{caso['id']}/{sospechoso['id']}:{campo}",
                    )
                ids.append(sospechoso["id"])
            self.assertEqual(len(ids), len(set(ids)), f"{caso['id']}: IDs de sospechoso duplicados")

    def test_caso9_r17_fija_el_corte_del_piloto(self):
        casos_por_id = {caso["id"]: caso for caso in self.casos}
        self.assertIn("caso9@9", casos_por_id)
        caso = casos_por_id["caso9@9"]

        self.assertEqual(caso["titulo"], "CASO_9_TITULO")
        self.assertEqual(len(caso["registros"]), 6)
        self.assertEqual(len(caso["sospechosos"]), 3)
        self.assertGreaterEqual(sum("fraseGatillo" in pista for pista in caso["pistas"]), 2)
        self.assertGreaterEqual(sum("registroOrigen2" in pista for pista in caso["pistas"]), 2)
        self.assertIn("CASO_9_TITULO,", TEXTOS.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
