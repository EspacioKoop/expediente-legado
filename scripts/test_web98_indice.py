import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "web98_indice.json"
MODELO = ROOT / "godot" / "guion" / "web98_indice.gd"
PRUEBA_GODOT = ROOT / "godot" / "pruebas" / "pruebas_web98_indice.gd"
COMPANEROS = ROOT / "godot" / "guion" / "companeros.gd"


def cargar_catalogo() -> dict:
    return json.loads(CATALOGO.read_text(encoding="utf-8"))


class Web98IndiceTest(unittest.TestCase):
    def test_catalogo_declara_una_red_pequena_y_coherente(self) -> None:
        datos = cargar_catalogo()
        recursos = datos["recursos"]
        categorias = {categoria["id"] for categoria in datos["categorias"]}

        self.assertEqual(datos["version"], 1)
        self.assertGreaterEqual(len(recursos), 12)
        self.assertGreaterEqual(len(categorias), 5)

        ids = [recurso["id"] for recurso in recursos]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(any(not recurso["indexado"] for recurso in recursos))

        for recurso in recursos:
            self.assertTrue(recurso["url"].startswith("http://"))
            self.assertTrue(recurso["titulo"])
            self.assertTrue(recurso["snippet"])
            self.assertIn(recurso["categoria"], categorias)
            self.assertIsInstance(recurso["terminos"], list)
            self.assertGreaterEqual(len(recurso["terminos"]), 2)
            self.assertIsInstance(recurso["prioridad"], int)
            self.assertIsInstance(recurso["requiere_conocimiento"], list)
            self.assertIsInstance(recurso["mirrors"], list)
            self.assertIsInstance(recurso["enlaces"], list)

    def test_enlaces_mirrors_y_caches_tienen_referencias_estables(self) -> None:
        recursos = cargar_catalogo()["recursos"]
        ids = {recurso["id"] for recurso in recursos}
        urls: set[str] = set()
        mirrors = 0
        caches = 0

        for recurso in recursos:
            self.assertNotIn(recurso["url"], urls)
            urls.add(recurso["url"])
            for destino in recurso["enlaces"]:
                self.assertIn(destino, ids)
            for mirror in recurso["mirrors"]:
                self.assertNotIn(mirror, urls)
                urls.add(mirror)
                mirrors += 1
            if recurso["cache"] is not None:
                cache = recurso["cache"]
                self.assertGreaterEqual(cache["capturada_dia"], 1)
                self.assertTrue(cache["titulo"])
                self.assertTrue(cache["cuerpo_resumen"])
                caches += 1

        self.assertGreaterEqual(mirrors, 1)
        self.assertGreaterEqual(caches, 2)

    def test_huellas_personales_reutilizan_ids_reales_de_companeros(self) -> None:
        fuente = COMPANEROS.read_text(encoding="utf-8")
        ids_reales = set(re.findall(r'"id": "([a-z0-9_]+)"', fuente))
        personales = [
            recurso
            for recurso in cargar_catalogo()["recursos"]
            if recurso.get("companero_id")
        ]
        ids_personales = {recurso["companero_id"] for recurso in personales}

        self.assertGreaterEqual(len(ids_personales), 2)
        self.assertLessEqual(ids_personales, ids_reales)
        self.assertIn("becario", ids_personales)
        self.assertIn("telefono", ids_personales)
        for recurso in personales:
            self.assertTrue(recurso["huella"])

    def test_enlace13_esta_declarado_como_conocimiento_restringido(self) -> None:
        recursos = cargar_catalogo()["recursos"]
        sensibles = [
            recurso
            for recurso in recursos
            if "enlace13" in recurso.get("requiere_conocimiento", [])
        ]

        self.assertEqual(len(sensibles), 1)
        self.assertEqual(sensibles[0]["id"], "diagnostico-enlace13")
        self.assertIn("enlace13", sensibles[0]["terminos"])
        self.assertTrue(sensibles[0]["indexado"])

    def test_modelo_es_offline_y_no_toca_red_o_procesos_del_host(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn("class_name Web98Indice", fuente)
        self.assertIn("func buscar", fuente)
        self.assertIn("func directorio", fuente)
        self.assertIn("func resolver_url", fuente)
        self.assertIn("func cache_de", fuente)
        self.assertIn("func enlaces_desde", fuente)
        self.assertIn('FileAccess.get_file_as_string(ruta)', fuente)
        for prohibido in (
            "HTTPRequest",
            "HTTPClient",
            "TCPServer",
            "StreamPeerTCP",
            "WebSocketPeer",
            "OS.execute(",
            "OS.create_process(",
        ):
            self.assertNotIn(prohibido, fuente)

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
