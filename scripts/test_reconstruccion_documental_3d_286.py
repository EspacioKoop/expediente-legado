import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CASOS = ROOT / "godot" / "datos" / "casos.json"
RECONSTRUCCIONES = ROOT / "godot" / "datos" / "reconstrucciones_documentales.json"
SCRIPT = ROOT / "godot" / "guion" / "reconstruccion_documental_3d.gd"


class ReconstruccionesDocumentales286Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.casos = json.loads(CASOS.read_text(encoding="utf-8"))["casos"]
        cls.catalogo = json.loads(RECONSTRUCCIONES.read_text(encoding="utf-8"))
        cls.reconstrucciones = cls.catalogo["reconstrucciones"]

    def test_catalogo_cubre_los_diez_expedientes(self):
        self.assertEqual(
            {r["caso"] for r in self.reconstrucciones},
            {
                "caso@1",
                "caso2@2",
                "caso3@3",
                "caso4@4",
                "caso5@5",
                "caso6@6",
                "caso7@7",
                "caso8@8",
                "caso9@9",
                "caso10@10",
            },
        )
        self.assertGreaterEqual(len(self.reconstrucciones), 30)

    def test_cada_reconstruccion_apunta_a_un_folio_real(self):
        casos = {caso["id"]: caso for caso in self.casos}
        ids = set()
        for reconstruccion in self.reconstrucciones:
            self.assertNotIn(reconstruccion["id"], ids)
            ids.add(reconstruccion["id"])
            caso = casos[reconstruccion["caso"]]
            registros = {r["id"]: r for r in caso["registros"]}
            self.assertIn(reconstruccion["registro"], registros)
            registro = registros[reconstruccion["registro"]]
            self.assertEqual(reconstruccion["folio"], registro["folio"])

    def test_los_fragmentos_salen_literalmente_del_documento(self):
        casos = {caso["id"]: caso for caso in self.casos}
        for reconstruccion in self.reconstrucciones:
            registros = {r["id"]: r for r in casos[reconstruccion["caso"]]["registros"]}
            contenido = registros[reconstruccion["registro"]]["contenido"]
            self.assertGreaterEqual(len(reconstruccion["fragmentos"]), 2)
            for fragmento in reconstruccion["fragmentos"]:
                self.assertIn(
                    fragmento,
                    contenido,
                    f"{reconstruccion['id']}: fragmento no respaldado por {reconstruccion['folio']}",
                )

    def test_planos_son_breves_y_tienen_motivo(self):
        encuadres = {"general", "detalle", "fijo", "cenital"}
        for reconstruccion in self.reconstrucciones:
            self.assertGreaterEqual(len(reconstruccion["planos"]), 2)
            for plano in reconstruccion["planos"]:
                self.assertIn(plano["encuadre"], encuadres)
                self.assertGreater(plano["duracion"], 0)
                self.assertLessEqual(plano["duracion"], 3.0)
                self.assertTrue(plano["motivo"].strip())

    def test_runtime_filtra_por_registros_leidos_y_reduccion_movimiento(self):
        fuente = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("registros_leidos.has", fuente)
        self.assertIn("if reduccion_movimiento:", fuente)
        self.assertIn('encuadre = "fijo"', fuente)
        self.assertNotIn("culpable", fuente.lower())
        self.assertNotIn("responsable", fuente.lower())


if __name__ == "__main__":
    unittest.main()
