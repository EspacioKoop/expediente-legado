import json
import os
import subprocess
from pathlib import Path
import re
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
AMATEUR = ROOT / "godot" / "datos" / "web98_amateur.json"
COMPANEROS = ROOT / "godot" / "guion" / "companeros.gd"
PRUEBA_GODOT = ROOT / "godot" / "pruebas" / "pruebas_web98_amateur.gd"


def cargar() -> dict:
    return json.loads(AMATEUR.read_text(encoding="utf-8"))


class Web98AmateurTest(unittest.TestCase):
    def test_catalogo_declara_paginas_anillos_y_guestbooks(self) -> None:
        datos = cargar()
        recursos = datos["recursos"]
        amateur = [r for r in recursos if r.get("tipo") == "amateur"]
        anillos = [r for r in recursos if r.get("tipo") == "webring"]
        guestbooks = [r for r in recursos if r.get("tipo") == "guestbook"]

        self.assertEqual(datos["version"], 1)
        self.assertGreaterEqual(len(amateur), 8)
        self.assertGreaterEqual(len(anillos), 2)
        self.assertGreaterEqual(len(guestbooks), 2)

        ids = [r["id"] for r in recursos]
        urls = [r["url"] for r in recursos]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(len(urls), len(set(urls)))

    def test_webrings_tienen_grafo_y_navegacion_coherentes(self) -> None:
        recursos = cargar()["recursos"]
        por_id = {r["id"]: r for r in recursos}
        anillos = [r for r in recursos if r.get("tipo") == "webring"]

        for anillo in anillos:
            miembros = anillo["webring"]["miembros"]
            self.assertGreaterEqual(len(miembros), 4)
            self.assertTrue(anillo["indexado"])
            self.assertGreaterEqual(len(anillo.get("enlaces_rotulados", [])), 3)
            for miembro in miembros:
                if miembro.startswith("http://"):
                    self.assertNotIn(miembro, {r["url"] for r in recursos})
                else:
                    self.assertIn(miembro, por_id)

        paginas_ring = [r for r in recursos if r.get("tipo") == "amateur" and r.get("webring")]
        for pagina in paginas_ring:
            etiquetas = [e["etiqueta"] for e in pagina.get("enlaces_rotulados", [])]
            texto = " ".join(etiquetas)
            self.assertIn("Anterior", texto)
            self.assertIn("Índice", texto)
            self.assertIn("Siguiente", texto)

    def test_guestbooks_son_declarativos_y_fechados(self) -> None:
        guestbooks = [
            r for r in cargar()["recursos"] if r.get("tipo") == "guestbook"
        ]
        fecha_1998 = re.compile(r"^\d{2}/\d{2}/1998$")
        for libro in guestbooks:
            self.assertFalse(libro["indexado"])
            self.assertGreaterEqual(len(libro["entradas_guestbook"]), 2)
            self.assertNotIn("formulario", libro)
            self.assertNotIn("texto_libre", libro)
            for entrada in libro["entradas_guestbook"]:
                self.assertRegex(entrada["fecha"], fecha_1998)
                self.assertTrue(entrada["autor"])
                self.assertTrue(entrada["texto"])
                self.assertGreaterEqual(entrada["visible_desde_dia"], 1)

    def test_huellas_reutilizan_companeros_existentes(self) -> None:
        fuente = COMPANEROS.read_text(encoding="utf-8")
        ids_reales = set(re.findall(r'"id": "([a-z0-9_]+)"', fuente))
        huellas = [r for r in cargar()["recursos"] if r.get("companero_id")]
        ids_huellas = {r["companero_id"] for r in huellas}

        self.assertGreaterEqual(len(ids_huellas), 2)
        self.assertLessEqual(ids_huellas, ids_reales)
        for pagina in huellas:
            self.assertTrue(pagina["huella"])

    def test_mudanza_contadores_y_enlaces_muertos_son_datos(self) -> None:
        recursos = cargar()["recursos"]
        por_id = {r["id"]: r for r in recursos}
        urls = {r["url"] for r in recursos}

        mudadas = [r for r in recursos if r.get("movido_a")]
        self.assertGreaterEqual(len(mudadas), 1)
        for pagina in mudadas:
            self.assertIn(pagina["movido_a"], por_id)
            self.assertGreaterEqual(pagina["movido_desde_dia"], 2)
            self.assertTrue(pagina["mensaje_mudanza"])

        contadores = [r for r in recursos if "contador_base" in r]
        self.assertGreaterEqual(len(contadores), 6)
        for pagina in contadores:
            self.assertGreaterEqual(pagina["contador_base"], 0)
            self.assertGreaterEqual(pagina["contador_incremento_dia"], 0)

        enlaces_muertos = [
            enlace["url"]
            for r in recursos
            for enlace in r.get("enlaces_url", [])
        ]
        self.assertGreaterEqual(len(enlaces_muertos), 2)
        for url in enlaces_muertos:
            self.assertTrue(url.startswith("http://"))
            self.assertNotIn(url, urls)

    def test_contrato_ejecutable_en_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                str(PRUEBA_GODOT.relative_to(ROOT / "godot")),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
