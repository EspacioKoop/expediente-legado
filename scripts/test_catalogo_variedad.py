import importlib.util
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULO = ROOT / "scripts" / "catalogo_variedad.py"
CASOS = ROOT / "godot" / "datos" / "casos.json"

SPEC = importlib.util.spec_from_file_location("catalogo_variedad", MODULO)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mod)


def caso(
    case_id: str,
    tipos=("MEMORANDO", "ACTA"),
    registros=4,
    pistas=4,
    relaciones=1,
    gatillos=2,
    sospechosos=2,
):
    docs = [
        {
            "id": f"d{i}",
            "tipo": tipos[i % len(tipos)],
            "folio": f"F-{i}",
            "contenido": f"texto visible {i}",
        }
        for i in range(registros)
    ]
    clues = []
    for i in range(pistas):
        item = {
            "id": f"p{i}",
            "registroOrigen": docs[i % len(docs)]["id"],
            "descripcion": f"pista visible {i}",
        }
        if i < relaciones:
            item["registroOrigen2"] = docs[(i + 1) % len(docs)]["id"]
        if i < gatillos:
            item["fraseGatillo"] = f"frase visible {i}"
        clues.append(item)
    return {
        "id": case_id,
        "titulo": f"Título {case_id}",
        "descripcion": "texto editorial",
        "anioSuceso": 1998,
        "principal": True,
        "confidencial": False,
        "registros": docs,
        "pistas": clues,
        "sospechosos": [
            {"id": f"s{i}", "nombre": f"Nombre {i}", "desenlace": "texto"}
            for i in range(sospechosos)
        ],
    }


class CatalogoVariedadTest(unittest.TestCase):
    def test_texto_visible_no_cambia_el_perfil(self):
        a = caso("a")
        b = json.loads(json.dumps(a))
        b["titulo"] = "Completely different title"
        b["descripcion"] = "Another language"
        b["registros"][0]["contenido"] = "Translated body"
        b["pistas"][0]["descripcion"] = "Translated clue"
        b["sospechosos"][0]["nombre"] = "Another Name"
        self.assertEqual(mod.rasgos(mod.perfil(a)), mod.rasgos(mod.perfil(b)))

    def test_estructura_identica_tiene_similitud_uno(self):
        self.assertEqual(
            1.0,
            mod.similitud(mod.perfil(caso("a")), mod.perfil(caso("b"))),
        )

    def test_tipos_y_forma_distintos_reducen_similitud(self):
        a = mod.perfil(caso("a"))
        b = mod.perfil(
            caso(
                "b",
                tipos=("PARTE_IMPRENTA",),
                registros=1,
                pistas=1,
                relaciones=0,
                gatillos=0,
                sospechosos=1,
            )
        )
        self.assertLess(mod.similitud(a, b), 0.5)

    def test_analisis_es_determinista_aunque_cambie_el_orden(self):
        casos = [caso("c"), caso("a"), caso("b", tipos=("OFICIO", "CIRCULAR"))]
        uno = mod.analizar(casos)
        dos = mod.analizar(list(reversed(casos)))
        self.assertEqual(uno, dos)
        self.assertEqual(["a", "b", "c"], [p["id"] for p in uno["perfiles"]])

    def test_rechaza_ids_duplicados(self):
        with self.assertRaises(ValueError):
            mod.analizar([caso("a"), caso("a")])

    def test_catalogo_real_se_puede_medir_sin_mutarlo(self):
        originales = json.loads(CASOS.read_text(encoding="utf-8"))["casos"]
        copia = json.loads(json.dumps(originales))
        informe = mod.analizar(originales)
        self.assertEqual(len(originales), informe["casos"])
        self.assertEqual(originales, copia)
        self.assertGreaterEqual(informe["casos"], 11)
        self.assertGreater(informe["tipos_documento_unicos"], 0)
        self.assertEqual(
            informe["casos"] * (informe["casos"] - 1) // 2,
            len(list(__import__("itertools").combinations(informe["perfiles"], 2))),
        )

    def test_markdown_explica_que_no_es_politica_de_seleccion(self):
        informe = mod.analizar([caso("a"), caso("b")])
        texto = mod.markdown(informe)
        self.assertIn("Variedad estructural", texto)
        self.assertIn("no decide cuántos casos", texto)


if __name__ == "__main__":
    unittest.main()
